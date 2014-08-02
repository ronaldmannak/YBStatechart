//
//  YBStatechart.m
//  YBStatechart
//
//  Created by Martijn Thé on 3/26/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import "YBStatechart.h"
#import <objc/runtime.h>

NSString *YBStateEnterStateEvent = @"enterState";
NSString *YBStateExitStateEvent = @"exitState";

@interface YBStatechart () {
    @package
    __strong YBState *_rootState;
    __strong NSMutableDictionary *_registeredStates;
    BOOL _isActive;
}
@end

@interface YBState () {
    @package
    __strong NSString *_name;
    __strong NSString *_historyKey;
    __strong NSSet *_substates;
    __weak YBState *_superstate;
    __weak YBStatechart *_statechart;
    __strong NSMutableDictionary *_eventHandlers;
    BOOL _substatesAreOrthogonal;
    BOOL _active;
    BOOL _useHistory;
}
- (void)setStatechart:(YBStatechart*)statechart;
- (void)activate:(id)payload ;
- (void)activateDefaultSubstatesRecursive:(BOOL)recursive saveToHistory:(BOOL)saveToHistory withPayload:(id)payload;
- (void)activateSubstate:(YBState*)substate saveToHistory:(BOOL)saveToHistory withPayload:(id)payload ;
- (void)deactivate;
- (void)deactivateSubstatesExcept:(YBState*)exceptSubstate recursive:(BOOL)recursive;
- (void)handleEventAndDispatchToActiveSubstates:(NSString*)event withPayload:(id)payLoad;
#if DEBUG
- (BOOL)debugValidate;
#endif
@end





@implementation YBStatechart

//- (void)dealloc {
//    NSLog(@"dealloc statechart <%p>", self);
//}

- (id)init {
    self = [super init];
    if (self) {
        _registeredStates = [NSMutableDictionary dictionary];
    }
    return self;
}

#if DEBUG
- (BOOL)debugValidate {
    if (_rootState == nil) {
        NSLog(@"No rootState set!");
        return NO;
    }
    return [_rootState debugValidate];
}
#endif

- (void)deactivate {
    NSAssert(_rootState != nil, @"No rootState set.");
#if DEBUG
    BOOL valid = [self debugValidate];
    if (valid)
#endif
    {
        if (_rootState->_active == YES) {
            [_rootState deactivate];
            [_rootState deactivateSubstatesExcept:nil recursive:YES];
            _isActive = NO;
        }
    }
}

- (void)activate {
    NSAssert(_rootState != nil, @"No rootState set.");
#if DEBUG
    BOOL valid = [self debugValidate];
    if (valid)
#endif
    {
        [self activateState:_rootState];
        _isActive = YES;
    }
}

- (void)setRootState:(YBState *)rootState {
    if (rootState == _rootState) {
        return;
    }
    _rootState = rootState;
    [_rootState setStatechart:self];
    
    // todo: deactivate?
}

- (void)registerState:(YBState *)state {
    NSAssert([_registeredStates objectForKey:state.name] == nil || [_registeredStates objectForKey:state.name] == state, @"State names need to be unique within one statechart");
    [_registeredStates setObject:state forKey:state.name];
}

- (YBState*)findStateWithName:(NSString*)stateName {
    return [_registeredStates objectForKey:stateName];
}


- (void)activateStateWithName:(NSString*)stateName{
	[self activateStateWithName:stateName withPayload:nil];
}


- (void)activateStateWithName:(NSString*)stateName saveToHistory:(BOOL)saveToHistory{
	[self activateStateWithName:stateName saveToHistory:saveToHistory withPayload:nil];
}

- (void)activateState:(YBState*)state{
	[self activateState:state withPayload:nil];
}


- (void)activateState:(YBState*)state saveToHistory:(BOOL)saveToHistory{
	[self activateState:state saveToHistory:saveToHistory withPayload:nil];
}


- (void)activateStateWithName:(NSString*)stateName withPayload:(id)payload{
    [self activateStateWithName:stateName saveToHistory:YES withPayload:payload];
}

- (void)activateStateWithName:(NSString*)stateName saveToHistory:(BOOL)saveToHistory withPayload:(id)payload {
    YBState *state = [self findStateWithName:stateName];
    NSAssert(state != nil, @"Couldn't find state with name: %@", stateName);
    if (state->_active) {
        return;
    }
    [self activateState:state saveToHistory:saveToHistory withPayload:payload];
}

- (void)activateState:(YBState*)state withPayload:(id)payload{
    if (state->_active) {
        return;
    }
    [self activateState:state saveToHistory:YES withPayload:payload];
}

- (void)activateState:(YBState*)state saveToHistory:(BOOL)saveToHistory withPayload:(id)payload {
    if (state->_active) {
        return;
    }
    // Traverse the graph down to the root of the tree:
    YBState *downState = state;
    while (downState != nil) {
        if (downState->_superstate) {
            [downState->_superstate activateSubstate:downState saveToHistory:saveToHistory withPayload:payload
			 ];
        } else { // rootState doesn't have a superstate
            [downState activate:payload];
        }
        downState = downState->_superstate;
    }
    // Traverse the graph up the leaves of the tree:
    [state activateDefaultSubstatesRecursive:YES saveToHistory:saveToHistory withPayload:payload];
}

- (void)dispatchEvent:(NSString*)event withPayload:(id)payLoad {
    NSAssert(_rootState != nil, @"No rootState set.");
    [_rootState handleEventAndDispatchToActiveSubstates:event withPayload:payLoad];
}


- (void)dispatchEvent:(NSString*)event {
	[self dispatchEvent:event withPayload:nil];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if ([self respondsToSelector:aSelector]) {
        return [super methodSignatureForSelector:aSelector];
    } else {
        NSString *methodName = NSStringFromSelector(aSelector);
        if ([methodName rangeOfString:@":"].length == 0) { // is there another way to test for existence of arguments in a SEL?
            return [NSMethodSignature signatureWithObjCTypes:"v@:"];
        } else {
            return [super methodSignatureForSelector:aSelector];
        }
    }
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    NSMethodSignature *signature = [anInvocation methodSignature];
    if ([signature numberOfArguments] == 2 /* No arguments */) {
        [self dispatchEvent:NSStringFromSelector(selector)];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

@synthesize isActive = _isActive;
@synthesize rootState = _rootState;
@end





@implementation YBState 

//- (void)dealloc {
//    NSLog(@"dealloc %@", _name);
//}

+ (id)stateWithName:(NSString*)name {
    return [[self alloc] initWithName:name];
}

- (id)initWithName:(NSString*)name {
    NSAssert(name.length != 0, @"Cannot create state without a name");
    NSAssert([name rangeOfString:@"."].length == 0, @"Cannot create a state name containing a dot character (.)");
    self = [super init];
    if (self) {
        _name = name;
        _historyKey = [@"YBStateHistory_" stringByAppendingString:_name];
        _substates = [NSSet set];
        _eventHandlers = [NSMutableDictionary dictionary];
    }
    return self;
}

#if DEBUG
- (BOOL)debugValidate {
    if ([_substates count] > 1) {
        __block BOOL validates = YES;
        if (_substatesAreOrthogonal == NO && _initialSubstate == nil) {
            NSLog(@"No initial substate is set for state `%@` while there are multiple non-orthogonal substates.", _name);
            validates = NO;
        }
        [_substates enumerateObjectsUsingBlock:^(YBState *substate, BOOL *stop) {
            if ([substate debugValidate] == NO) {
                validates = NO;
            }
        }];
        return validates;
    } else if ([_substates count] == 1) {
        NSLog(@"There is only one substate for state `%@`. You might want to consider merging `%@` with it's superstate `%@`", _name, [[_substates anyObject] name], _name);
        return [[_substates anyObject] debugValidate];
    }
    return YES;
}
#endif

- (void)on:(NSString*)event doBlock:(YBStateEventHandler)handler {
    NSParameterAssert(event != nil);
    if (handler) {
        [_eventHandlers setObject:[handler copy] forKey:event];
    } else {
        [self removeHandlerForEvent:event];
    }
}

#define LOG_DEBUG
- (void)onEnterState:(YBStateEventHandler)handler {
#ifdef LOG_DEBUG
    NSLog(@">> %@",self.name);
#endif
    [self on:YBStateEnterStateEvent doBlock:handler];
}

- (void)onExitState:(YBStateEventHandler)handler {
#ifdef LOG_DEBUG
    NSLog(@"<< %@",self.name);
#endif
    [self on:YBStateExitStateEvent doBlock:handler];
}

- (void)removeHandlerForEvent:(NSString*)event {
    NSAssert(event != nil, @"Event name cannot be nil");
    [_eventHandlers removeObjectForKey:event];
}

- (YBState*)addSubstate:(YBState*)substate {
    if (substate == self) {
        // can't do recursion!
        return self;
    }
    if (substate->_superstate) {
        if (substate->_superstate != self) {
            // state is already a substate of another state
            [NSException raise:@"State is already a substate of another state" format:@"Superstate: %@", [substate->_superstate name]];
        }
        return self;
    }
    _substates = [_substates setByAddingObject:substate];
    substate->_superstate = self;
    [substate setStatechart:_statechart];
    return self;
}

- (YBState*)addSubstates:(YBState *)substates, ... {
    va_list list;
    va_start(list, substates);
    YBState *substate = substates;
    do {
        [self addSubstate:substate];
        substate = va_arg(list, YBState*);
    } while (substate);
    va_end(list);
    return self;
}

- (NSString*)path {
    if (_superstate == nil) {
        return _name;
    } else {
        // todo: maybe cache this if called a lot
        return [[[_superstate path] stringByAppendingString:@"."] stringByAppendingString:_name];
    }
}

- (YBState*)substateWithName:(NSString*)stateName {
    __block YBState *foundSubstate = nil;
    [_substates enumerateObjectsUsingBlock:^(YBState *substate, BOOL *stop) {
        if ([[substate name] isEqualToString:stateName]) {
            foundSubstate = substate;
            *stop = YES;
        }
    }];
    return foundSubstate;
}

- (void)setHistorySubstate:(YBState *)historySubstate {
    if (historySubstate == self) {
        // can't do recursion!
        return;
    }
    // Add implicitely to self.substates if not already added:
    if (historySubstate != nil && [_substates containsObject:historySubstate] == NO) {
        [self addSubstate:historySubstate];
    }
    if (historySubstate != nil) {
        [[NSUserDefaults standardUserDefaults] setValue:historySubstate.name forKey:_historyKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:_historyKey];
    }
}

- (YBState*)historySubstate {
    NSString *substateName = [[NSUserDefaults standardUserDefaults] valueForKey:_historyKey];
    if (substateName.length == 0) {
        return nil;
    } else {
        return [self substateWithName:substateName];
    }
}

- (void)setInitialSubstate:(YBState *)initialSubstate {
    if (initialSubstate == self) {
        // can't do recursion!
        return;
    }
    // Add implicitely to self.substates if not already added:
    if (initialSubstate != nil && [_substates containsObject:initialSubstate] == NO) {
        [self addSubstate:initialSubstate];
    }
    _initialSubstate = initialSubstate;
}

// Private
- (void)setStatechart:(YBStatechart*)statechart {
    _statechart = statechart;
    [_statechart registerState:self];
    [_substates enumerateObjectsUsingBlock:^(YBState *substate, BOOL *stop) {
        [substate setStatechart:statechart];
    }];
}

- (void)deactivateSubstatesExcept:(YBState*)exceptSubstate recursive:(BOOL)recursive {
    if ([_substates count] == 0) {
        return;
    } else {
        [_substates enumerateObjectsUsingBlock:^(YBState *otherSubstate, BOOL *stop) {
            if (otherSubstate != exceptSubstate) {
                [otherSubstate deactivate];
                [otherSubstate deactivateSubstatesExcept:nil recursive:recursive];
            }
        }];
    }
}

- (void)activateDefaultSubstatesRecursive:(BOOL)recursive saveToHistory:(BOOL)saveToHistory withPayload:(id)payload {
    if ([_substates count] == 0) {
        return;
    } else if ([_substates count] == 1) {
        [self activateSubstate:[_substates anyObject] saveToHistory:saveToHistory withPayload:payload];
    } else {
        if (_substatesAreOrthogonal == NO) {
            // Figure out which substate to activate:
            YBState *defaultSubstate = nil;
            if (_useHistory) {
                defaultSubstate = [self historySubstate];
            }
            if (defaultSubstate == nil) {
                defaultSubstate = [self initialSubstate];
                NSAssert(defaultSubstate != nil, @"There is no initialSubstate set on `%@`. The statechart is not fully-defined!", _name);
            }
            [self activateSubstate:defaultSubstate saveToHistory:saveToHistory withPayload:payload];
            if (recursive) {
                [defaultSubstate activateDefaultSubstatesRecursive:recursive saveToHistory:saveToHistory withPayload:payload]; // recurse
            }
        } else {
            // Activate all substates (they're orthogonal):
            [_substates enumerateObjectsUsingBlock:^(YBState *substate, BOOL *stop) {
                [self activateSubstate:substate saveToHistory:saveToHistory withPayload:payload];
                if (recursive) {
                    [substate activateDefaultSubstatesRecursive:recursive saveToHistory:saveToHistory withPayload:payload];
                }
            }];
        }
    }
}

- (void)deactivate {
    if (_active == YES) {
        _active = NO;
        [self handleEvent:YBStateExitStateEvent withPayload:nil];
    }
}

- (void)activate:(id)payload {
    if (_active == NO) {
        _active = YES;
        [self handleEvent:YBStateEnterStateEvent withPayload:payload];
    }
}


- (void)activateSubstate:(YBState*)substate saveToHistory:(BOOL)saveToHistory withPayload:(id)payload {
    NSAssert([_substates containsObject:substate], @"State `%@` does not contain substate `%@`", _name, substate.name);
    if (substate->_active) {
        return;
    } else {
        if (_substatesAreOrthogonal) {
            [_substates enumerateObjectsUsingBlock:^(YBState *otherSubstate, BOOL *stop) {
                [otherSubstate activate:payload];
            }];
        } else {
            [self deactivateSubstatesExcept:substate recursive:YES];
            if (saveToHistory) {
                [self setHistorySubstate:substate];
            }
            [substate activate:payload];
        }
    }
}

- (void)handleEventAndDispatchToActiveSubstates:(NSString*)event withPayload:(id)payLoad {
    [self handleEvent:event withPayload:payLoad];
    
    if ([_substates count] == 0) {
        return;
    } else if ([_substates count] == 1) {
        [[_substates anyObject] handleEventAndDispatchToActiveSubstates:event withPayload:payLoad];
    } else {
        [_substates enumerateObjectsUsingBlock:^(YBState *substate, BOOL *stop) {
            if (substate->_active) {
                [substate handleEventAndDispatchToActiveSubstates:event withPayload:payLoad];
            }
        }];
    }
}

- (void)handleEvent:(NSString*)event withPayload:(id)payLoad {
    YBStateEventHandler handler = [_eventHandlers objectForKey:event];
    if (handler) {
        handler(self,payLoad);
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@ %p: `%@` (%@), %i substates, statechart=%p, superstate=%p, path=%@>", [self class], self, _name, _active ? @"active" : @"inactive", [_substates count], _statechart, _superstate, [self path]];
}

@synthesize initialSubstate = _initialSubstate;
@synthesize name = _name;
@synthesize substates = _substates;
@synthesize superstate = _superstate;
@synthesize statechart = _statechart;
@synthesize isActive = _active;
@synthesize substatesAreOrthogonal = _substatesAreOrthogonal;
@synthesize useHistory = _useHistory;
@end