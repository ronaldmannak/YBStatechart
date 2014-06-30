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
    STAssertTrue([[superstate substates] containsObject:substate] == YES, nil);
    STAssertTrue([substate superstate] == superstate,  nil);
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
    STAssertTrue(rootState == superstate, nil);
    [[rootState substates] enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(YBState *substate, BOOL *stop) {
        STAssertTrue([substate statechart] == statechart, nil);
    }];
}

- (void)testStatechartPropertyAfterSettingRootstate {
    YBStatechart *statechart = [[YBStatechart alloc] init];
    YBState *superstate = [YBState stateWithName:@"superState"];
    YBState *substate = [YBState stateWithName:@"subState"];
    [statechart setRootState:superstate];
    [superstate addSubstate:substate];
    STAssertTrue([substate statechart] == statechart, nil);
}

- (void)testImplicitAddingWhenSettingInitialSubstate {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    YBState *substate = [YBState stateWithName:@"substate"];
    superstate.initialSubstate = substate;
    STAssertTrue([[superstate substates] containsObject:substate], @"initialSubstate setter is expected to implicitely add the assigned state as substate");
}

- (void)testImplicitAddingWhenSettingHistorySubstate {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    YBState *substate = [YBState stateWithName:@"substate"];
    superstate.historySubstate = substate;
    STAssertTrue([[superstate substates] containsObject:substate], @"historySubstate setter is expected to implicitely add the assigned state as substate");
}

- (void)testHistorySubstate {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    YBState *substate = [YBState stateWithName:@"substate"];
    superstate.historySubstate = substate;
    STAssertTrue(superstate.historySubstate == substate, nil);
    superstate.historySubstate = nil;
    STAssertTrue(superstate.historySubstate == nil, nil);
}

- (void)testInitialSubstate {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    YBState *substate = [YBState stateWithName:@"substate"];
    superstate.initialSubstate = substate;
    STAssertTrue(superstate.initialSubstate == substate, nil);
    superstate.initialSubstate = nil;
    STAssertTrue(superstate.initialSubstate == nil, nil);
}

- (void)testDisallowRecursion {
    YBState *superstate = [YBState stateWithName:@"superstate"];
    [superstate addSubstate:superstate];
    STAssertTrue([[superstate substates] containsObject:superstate] == NO, nil);
    superstate.initialSubstate = superstate;
    STAssertTrue(superstate.initialSubstate == nil, nil);
    superstate.historySubstate = superstate;
    STAssertTrue(superstate.historySubstate == nil, nil);
}

- (void)testActivatingStates {
    YBStatechart *statechart = [[YBStatechart alloc] init];
    STAssertTrue([statechart debugValidate] == NO, nil);

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
    STAssertTrue([statechart debugValidate] == NO, nil);
    rootState.initialSubstate = substate1;
    STAssertTrue([statechart debugValidate] == NO, nil);
    substate1.initialSubstate = substate1_1;
    STAssertTrue([statechart debugValidate] == NO, nil);
    substate2_2.initialSubstate = substate2_2_1;
    STAssertTrue([statechart debugValidate] == YES, nil);
    
    // Test initial activations:
    [statechart activate];
    STAssertTrue(rootState.isActive == YES, nil);
    STAssertTrue(statechart.isActive == YES, nil);
    STAssertTrue(substate1.isActive == YES, nil);
    STAssertTrue(substate1_1.isActive == YES, nil);

    STAssertTrue(substate1_2.isActive == NO, nil);
    STAssertTrue(substate2.isActive == NO, nil);
    STAssertTrue(substate2_1.isActive == NO, nil);
    STAssertTrue(substate2_2.isActive == NO, nil);
    STAssertTrue(substate2_2_1.isActive == NO, nil);
    STAssertTrue(substate2_2_2.isActive == NO, nil);
    
    // Test leaf state change:
    [statechart activateState:substate1_2];
    STAssertTrue(statechart.isActive == YES, nil);
    STAssertTrue(substate1.isActive == YES, nil);
    STAssertTrue(substate1_2.isActive == YES, nil);
    
    STAssertTrue(substate1_1.isActive == NO, nil);
    STAssertTrue(substate2.isActive == NO, nil);
    STAssertTrue(substate2_1.isActive == NO, nil);
    STAssertTrue(substate2_2.isActive == NO, nil);
    STAssertTrue(substate2_2_1.isActive == NO, nil);
    STAssertTrue(substate2_2_2.isActive == NO, nil);
    
    // Test activating orthogonal substates:
    [statechart activateStateWithName:@"2"];
    STAssertTrue(statechart.isActive == YES, nil);
    STAssertTrue(substate2.isActive == YES, nil);
    STAssertTrue(substate2_1.isActive == YES, nil);
    STAssertTrue(substate2_2.isActive == YES, nil);
    STAssertTrue(substate2_2_1.isActive == YES, nil);
    
    STAssertTrue(substate1.isActive == NO, nil);
    STAssertTrue(substate1_1.isActive == NO, nil);
    STAssertTrue(substate1_2.isActive == NO, nil);
    STAssertTrue(substate2_2_2.isActive == NO, nil);
    
    // Testing leaf state change:
    [statechart activateState:substate2_2_2];
    STAssertTrue(statechart.isActive == YES, nil);
    STAssertTrue(substate2.isActive == YES, nil);
    STAssertTrue(substate2_1.isActive == YES, nil);
    STAssertTrue(substate2_2.isActive == YES, nil);
    STAssertTrue(substate2_2_2.isActive == YES, nil);
    
    STAssertTrue(substate1.isActive == NO, nil);
    STAssertTrue(substate1_1.isActive == NO, nil);
    STAssertTrue(substate1_2.isActive == NO, nil);
    STAssertTrue(substate2_2_1.isActive == NO, nil);
    
    // Testing reverting to history of state1_2:
    [statechart activateState:substate1];
    STAssertTrue(substate1.isActive == YES, nil);
    STAssertTrue(substate1_2.isActive == YES, nil);
    
    STAssertTrue(substate1_1.isActive == NO, nil);
    STAssertTrue(substate2.isActive == NO, nil);
    STAssertTrue(substate2_1.isActive == NO, nil);
    STAssertTrue(substate2_2.isActive == NO, nil);
    STAssertTrue(substate2_2_1.isActive == NO, nil);
    STAssertTrue(substate2_2_2.isActive == NO, nil);
}

- (void)testChartDispatchDirect {
    __block BOOL didButtonDown = NO;
    STAssertTrue(didButtonDown == NO, nil);
    YBStatechart *statechart = [[YBStatechart alloc] init];
    YBState *rootState = [YBState stateWithName:@"rootState"];
    [rootState on:@"buttonDown" doBlock:^(YBState *_self , id payload) {
        didButtonDown = YES;
    }];
    
    [statechart setRootState:rootState];
    [statechart performSelector:@selector(buttonDown)];
    STAssertTrue(didButtonDown == YES, nil);
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
    
    [rootState on:@"toggle" doBlock:^(YBState *_self , id payload) {
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
    
    STAssertTrue([enterSet containsObject:rootState] == YES, nil);
    STAssertTrue([enterSet containsObject:loggedOut] == YES, nil); // initial substate of rootState
    STAssertTrue([enterSet containsObject:loggedIn] == NO, nil);
    STAssertTrue([exitSet count] == 0, nil);
    
    [statechart performSelector:@selector(up)];
    STAssertTrue([eventSet containsObject:rootState] == YES, nil);
    STAssertTrue([eventSet containsObject:loggedOut] == YES, nil);
    STAssertTrue([eventSet containsObject:loggedIn] == NO, nil);

    [statechart performSelector:@selector(toggle)];
    STAssertTrue([enterSet containsObject:loggedIn] == YES, nil);
    STAssertTrue([exitSet containsObject:loggedOut] == YES, nil);

    [statechart performSelector:@selector(up)];
    STAssertTrue([eventSet containsObject:loggedIn] == YES, nil);
    
    [statechart deactivate];
    STAssertTrue([exitSet count] == 3, nil);
    
    // Break retain cycles (the states are retained by the sets, which are used/retained inside the handlers blocks, which are retained by the states):
    [enterSet removeAllObjects];
    [exitSet removeAllObjects];
    [eventSet removeAllObjects];
}

@end
