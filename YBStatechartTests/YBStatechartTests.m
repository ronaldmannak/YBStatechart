//
//  YBStatechartTests.m
//  YBStatechartTests
//
//  Created by Martijn Thé on 3/26/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBStatechartTests.h"
#import "YBStatechart.h"

@implementation YBStatechartTests

- (void)testAddSubstate {
    YBState *superstate = [YBState stateWithName:@"superState"];
    YBState *substate = [YBState stateWithName:@"subState"];
    [superstate addSubstate:substate];
    XCTAssertTrue([[superstate substates] containsObject:substate] == YES);
    XCTAssertTrue([substate superstate] == superstate);
}

- (void)testSetRootstateAndAutomaticStatechartPropertyAssignment {
    YBStatechart *statechart = [[YBStatechart alloc] init];
    YBState *superstate = [YBState stateWithName:@"superState"];
    YBState *substate1 = [YBState stateWithName:@"subState1"];
    YBState *substate2 = [YBState stateWithName:@"subState2"];
    YBState *substate3 = [YBState stateWithName:@"subState3"];
    [superstate addSubstate:substate1];
    [superstate addSubstate:substate2];
    [superstate addSubstate:substate3];
    [statechart setRootState:superstate];
    
    YBState *rootState = [statechart rootState];
    XCTAssertTrue(rootState == superstate);
    [[rootState substates] enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(YBState *substate, BOOL *stop) {
        XCTAssertTrue([substate statechart] == statechart);
    }];
}

- (void)testStatechartPropertyAfterSettingRootstate {
    YBStatechart *statechart = [[YBStatechart alloc] init];
    YBState *superstate = [YBState stateWithName:@"superState"];
    YBState *substate = [YBState stateWithName:@"subState"];
    [statechart setRootState:superstate];
    [superstate addSubstate:substate];
    XCTAssertTrue([substate statechart] == statechart);
}

- (void)testImplicitAddingWhenSettingInitialSubstate {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    YBState *substate = [YBState stateWithName:@"substate"];
    superstate.initialSubstate = substate;
    XCTAssertTrue([[superstate substates] containsObject:substate], @"initialSubstate setter is expected to implicitely add the assigned state as substate");
}

- (void)testImplicitAddingWhenSettingHistorySubstate {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    YBState *substate = [YBState stateWithName:@"substate"];
    superstate.historySubstate = substate;
    XCTAssertTrue([[superstate substates] containsObject:substate], @"historySubstate setter is expected to implicitely add the assigned state as substate");
}

- (void)testHistorySubstate {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    YBState *substate = [YBState stateWithName:@"substate"];
    superstate.historySubstate = substate;
    XCTAssertTrue(superstate.historySubstate == substate);
    superstate.historySubstate = nil;
    XCTAssertTrue(superstate.historySubstate == nil);
}

- (void)testInitialSubstate {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    YBState *substate = [YBState stateWithName:@"substate"];
    superstate.initialSubstate = substate;
    XCTAssertTrue(superstate.initialSubstate == substate);
    superstate.initialSubstate = nil;
    XCTAssertTrue(superstate.initialSubstate == nil);
}

- (void)testDisallowRecursion {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    [superstate addSubstate:superstate];
    XCTAssertTrue([[superstate substates] containsObject:superstate] == NO);
    superstate.initialSubstate = superstate;
    XCTAssertTrue(superstate.initialSubstate == nil);
    superstate.historySubstate = superstate;
    XCTAssertTrue(superstate.historySubstate == nil);
}

- (void)testActivatingStates {
    YBStatechart *statechart = [[YBStatechart alloc] init];
    XCTAssertTrue([statechart debugValidate] == NO);

    // State 1 has 2 substates + history:
    YBState *substate1 = [YBState stateWithName:@"1"];
    substate1.useHistory = YES;
    [substate1 setHistorySubstate:nil]; // clear history
    YBState *substate1_1 = [YBState stateWithName:@"1_1"];
    YBState *substate1_2 = [YBState stateWithName:@"1_2"];
    [substate1 addSubstate:substate1_1];
    [substate1 addSubstate:substate1_2];
    
    // State 2 has 2 orthogonal substates:
    YBState *substate2 = [YBState stateWithName:@"2"];
    substate2.substatesAreOrthogonal = YES;
    YBState *substate2_1 = [YBState stateWithName:@"2_1"];
    YBState *substate2_2 = [YBState stateWithName:@"2_2"];
    [substate2 addSubstate:substate2_1];
    [substate2 addSubstate:substate2_2];
    
    // State 2.2 has 2 substates:
    YBState *substate2_2_1 = [YBState stateWithName:@"2_2_1"];
    YBState *substate2_2_2 = [YBState stateWithName:@"2_2_2"];
    [substate2_2 addSubstate:substate2_2_1];
    [substate2_2 addSubstate:substate2_2_2];
    
    YBState *rootState = [YBState stateWithName:@"rootState"];
    [rootState addSubstate:substate1];
    [rootState addSubstate:substate2];
    [statechart setRootState:rootState];
    
    // Set initialSubstates and validate the chart in between:
    XCTAssertTrue([statechart debugValidate] == NO);
    rootState.initialSubstate = substate1;
    XCTAssertTrue([statechart debugValidate] == NO);
    substate1.initialSubstate = substate1_1;
    XCTAssertTrue([statechart debugValidate] == NO);
    substate2_2.initialSubstate = substate2_2_1;
    XCTAssertTrue([statechart debugValidate] == YES);
    
    // Test initial activations:
    [statechart activate];
    XCTAssertTrue(rootState.isActive == YES);
    XCTAssertTrue(statechart.isActive == YES);
    XCTAssertTrue(substate1.isActive == YES);
    XCTAssertTrue(substate1_1.isActive == YES);

    XCTAssertTrue(substate1_2.isActive == NO);
    XCTAssertTrue(substate2.isActive == NO);
    XCTAssertTrue(substate2_1.isActive == NO);
    XCTAssertTrue(substate2_2.isActive == NO);
    XCTAssertTrue(substate2_2_1.isActive == NO);
    XCTAssertTrue(substate2_2_2.isActive == NO);
    
    // Test leaf state change:
    [statechart activateState:substate1_2];
    XCTAssertTrue(statechart.isActive == YES);
    XCTAssertTrue(substate1.isActive == YES);
    XCTAssertTrue(substate1_2.isActive == YES);
    
    XCTAssertTrue(substate1_1.isActive == NO);
    XCTAssertTrue(substate2.isActive == NO);
    XCTAssertTrue(substate2_1.isActive == NO);
    XCTAssertTrue(substate2_2.isActive == NO);
    XCTAssertTrue(substate2_2_1.isActive == NO);
    XCTAssertTrue(substate2_2_2.isActive == NO);
    
    // Test activating orthogonal substates:
    [statechart activateStateWithName:@"2"];
    XCTAssertTrue(statechart.isActive == YES);
    XCTAssertTrue(substate2.isActive == YES);
    XCTAssertTrue(substate2_1.isActive == YES);
    XCTAssertTrue(substate2_2.isActive == YES);
    XCTAssertTrue(substate2_2_1.isActive == YES);
    
    XCTAssertTrue(substate1.isActive == NO);
    XCTAssertTrue(substate1_1.isActive == NO);
    XCTAssertTrue(substate1_2.isActive == NO);
    XCTAssertTrue(substate2_2_2.isActive == NO);
    
    // Testing leaf state change:
    [statechart activateState:substate2_2_2];
    XCTAssertTrue(statechart.isActive == YES);
    XCTAssertTrue(substate2.isActive == YES);
    XCTAssertTrue(substate2_1.isActive == YES);
    XCTAssertTrue(substate2_2.isActive == YES);
    XCTAssertTrue(substate2_2_2.isActive == YES);
    
    XCTAssertTrue(substate1.isActive == NO);
    XCTAssertTrue(substate1_1.isActive == NO);
    XCTAssertTrue(substate1_2.isActive == NO);
    XCTAssertTrue(substate2_2_1.isActive == NO);
    
    // Testing reverting to history of state1_2:
    [statechart activateState:substate1];
    XCTAssertTrue(substate1.isActive == YES);
    XCTAssertTrue(substate1_2.isActive == YES);
    
    XCTAssertTrue(substate1_1.isActive == NO);
    XCTAssertTrue(substate2.isActive == NO);
    XCTAssertTrue(substate2_1.isActive == NO);
    XCTAssertTrue(substate2_2.isActive == NO);
    XCTAssertTrue(substate2_2_1.isActive == NO);
    XCTAssertTrue(substate2_2_2.isActive == NO);
}

- (void)testChartDispatchDirect {
    __block BOOL didButtonDown = NO;
    XCTAssertTrue(didButtonDown == NO);
    YBStatechart *statechart = [[YBStatechart alloc] init];
    YBState *rootState = [YBState stateWithName:@"rootState"];
    [rootState on:@"buttonDown" doBlock:^(YBState *_self) {
        didButtonDown = YES;
    }];
    
    [statechart setRootState:rootState];
    [statechart performSelector:@selector(buttonDown)];
    XCTAssertTrue(didButtonDown == YES);
}

- (void)testNestedDispatch {
    YBState *loggedOut = [YBState stateWithName:@"loggedOut"];
    YBState *loggedIn = [YBState stateWithName:@"loggedIn"];
    YBState *rootState = [YBState stateWithName:@"rootState"];
    NSMutableSet *enterSet = [NSMutableSet set];
    NSMutableSet *exitSet = [NSMutableSet set];
    NSMutableSet *eventSet = [NSMutableSet set];
    
    id enterHandler = ^(YBState *_self){
        [enterSet addObject:_self];
    };
    
    id exitHandler = ^(YBState *_self){
        [exitSet addObject:_self];
    };
    
    id eventHandler = ^(YBState *_self){
        [eventSet addObject:_self];
    };
    
    [rootState onEnterState:enterHandler];
    [loggedIn onEnterState:enterHandler];
    [loggedOut onEnterState:enterHandler];

    [rootState onExitState:exitHandler];
    [loggedIn onExitState:exitHandler];
    [loggedOut onExitState:exitHandler];
    
    [rootState on:@"up" doBlock:eventHandler];
    [loggedIn on:@"up" doBlock:eventHandler];
    [loggedOut on:@"up" doBlock:eventHandler];
    
    [rootState on:@"toggle" doBlock:^(YBState *_self) {
        YBStatechart *statechart = _self.statechart;
        if (loggedIn.isActive) {
            [statechart activateState:loggedOut];
        } else {
            [statechart activateState:loggedIn];
        }
    }];
    
    rootState.initialSubstate = loggedOut;
    [rootState addSubstate:loggedOut];
    [rootState addSubstate:loggedIn];
    
    YBStatechart *statechart = [[YBStatechart alloc] init];
    statechart.rootState = rootState;
    [statechart activate];
    
    XCTAssertTrue([enterSet containsObject:rootState] == YES);
    XCTAssertTrue([enterSet containsObject:loggedOut] == YES); // initial substate of rootState
    XCTAssertTrue([enterSet containsObject:loggedIn] == NO);
    XCTAssertTrue([exitSet count] == 0);
    
    [statechart performSelector:@selector(up)];
    XCTAssertTrue([eventSet containsObject:rootState] == YES);
    XCTAssertTrue([eventSet containsObject:loggedOut] == YES);
    XCTAssertTrue([eventSet containsObject:loggedIn] == NO);

    [statechart performSelector:@selector(toggle)];
    XCTAssertTrue([enterSet containsObject:loggedIn] == YES);
    XCTAssertTrue([exitSet containsObject:loggedOut] == YES);

    [statechart performSelector:@selector(up)];
    XCTAssertTrue([eventSet containsObject:loggedIn] == YES);
    
    [statechart deactivate];
    XCTAssertTrue([exitSet count] == 3);
    
    // Break retain cycles (the states are retained by the sets, which are used/retained inside the handlers blocks, which are retained by the states):
    [enterSet removeAllObjects];
    [exitSet removeAllObjects];
    [eventSet removeAllObjects];
}

@end
