//
//  YBStatechart.h
//  YBStatechart
//
//  Created by Martijn Thé on 3/26/12.
//  Copyright (c) 2012 Yobble. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YBStatechart;
@class YBState;

extern NSString *YBStateEnterStateEvent;
extern NSString *YBStateExitStateEvent;

/**
	The block type used as event handler in a YBState object.
    The state object itself is passed to the block as the first argument.
	@param _self : The state object to which the handler belongs.
 */
typedef void(^YBStateEventHandler)(YBState *_self , id payload);



/**
	Statecharts are represented using instances of YBStatechart.
    For more information on statecharts, see David Harel's white paper from 1986:
    http://www.wisdom.weizmann.ac.il/~harel/SCANNED.PAPERS/Statecharts.pdf
 
    A statechart object contains one rootState, which acts as an encapsulation for other substates (which can in turn have other substates
    as well). A YBStatechart instance plays the central role of activating a particular state and ensuring the appropriate sibling-,
    sub- and super- states get activated and deactivated.
 
    Another important role is the dispatch of events, @see -dispatchEvent:
    When an unknown selector (with no arguments) gets sent to a statechart, it will use the selector name and use that as an event to
    dispatch it to the states in the chart. Because of this behaviour, statechart objects can be used conveniently in combination with
    target-selector style objects (e.g. UIButton).
 */
@interface YBStatechart : NSObject

/**
	The top-level state that encapsulates every other state inside the statechart.
    Setting the rootState will automatically associate all the states with the statechart.
 */
@property (nonatomic, strong, readwrite) YBState *rootState;

/**
	Attemps to find the state with given name in all the states that are currently associated with the statechart.
	@param stateName - The name of the state to look for
	@returns - The found state or nil if no state could be found
 */
- (YBState*)findStateWithName:(NSString*)stateName;

/**
    Methods to activate a given state in the statechart, either by passing in the state object itself or by passing in the name of the state.
    By default, automatic setting the historySubstate is enabled, but can be disabled using the saveToHistory argument.
 */



- (void)activateStateWithName:(NSString*)stateName;
- (void)activateStateWithName:(NSString*)stateName withPayload:(id)payload;
- (void)activateStateWithName:(NSString*)stateName saveToHistory:(BOOL)saveToHistory;
- (void)activateStateWithName:(NSString*)stateName saveToHistory:(BOOL)saveToHistory withPayload:(id)payload;
- (void)activateState:(YBState*)state;
- (void)activateState:(YBState*)state withPayload:(id)payload;
- (void)activateState:(YBState*)state saveToHistory:(BOOL)saveToHistory;
- (void)activateState:(YBState*)state saveToHistory:(BOOL)saveToHistory withPayload:(id)payload;

/**
	Activates the statechart. All initial and/or history substates will be entered/activated.
    @see isActive
 */
- (void)activate;

/**
    Deactivates the statechart. The rootState and all active substates branches will be exited/deactivated.
    @see isActive
 */
- (void)deactivate;

/**
	Returns YES if the statechart is active or NO is it is inactive.
 */
@property (nonatomic, assign, readonly) BOOL isActive;

/**
	Dispatches the given event to the active states in the statechart, causing the registered handlers to get called.
    This method will also be called when an unknown message with no arguments and void return type is sent to a statechart, e.g.:
    Sending [statechart buttonUp] will result in [statechart dispatchEvent:@"buttonUp"].
	@param event - The event to dispatch.
 */
- (void)dispatchEvent:(NSString*)event;

/**
 Dispatches the given event to the active states in the statechart, causing the registered handlers to get called.
 This method will also be called when an unknown message with no arguments and void return type is sent to a statechart, e.g.:
 Sending [statechart buttonUp] will result in [statechart dispatchEvent:@"buttonUp"].
 @param event - The event to dispatch.
 @param payLoad - Payload to dispatch with the event for context.
 */
- (void)dispatchEvent:(NSString*)event withPayload:(id)payLoad;

@end



@interface YBState : NSObject

/**
	Designated initializer to set up a new state object.
	@param name - The name of the state. State names in a statechart need to be unique.
	@returns - The initialized, inactive state object
 */
- (id)initWithName:(NSString*)name;

/**
	Convenience factory method to allocate and set up a new state object.
	@param name - The name of the state. State names in a statechart need to be unique.
	@returns The initialized, inactive state object
 */
+ (id)stateWithName:(NSString*)name;

/**
	@returns The path of states from the receiver up to the rootState, as a keyPath-style string (e.g. `rootState.substate1.substate2`)
 */
- (NSString*)path;

/**
    Registers an event handler block with an event
    @param event - name of the event (selector)
    @param handler - block that will be called when the state is active and the event occurs
 */
- (void)on:(NSString*)event doBlock:(YBStateEventHandler)handler;

/**
	Convenience method to register the event handler for the `enterState` event.
	@param handler - block that will be called when the state is entered
 */
- (void)onEnterState:(YBStateEventHandler)handler;

/**
    Convenience method to register the event handler for the `exitState` event.
    @param handler - block that will be called when the state is exited
 */
- (void)onExitState:(YBStateEventHandler)handler;

/**
	Unregisters the event handler block with an event
	@param event - name of the event (selector)
 */
- (void)removeHandlerForEvent:(NSString*)event;

/**
	Makes the given state a substate of the receiver. This will automatically make the receiver the superstate of the given state.
	@param substate - the state to add to as substate
    @return Returns the receiver, to enable chaining-style programming
 */
- (YBState*)addSubstate:(YBState*)substate;

/**
    Convenience method to add multiple substates. Supply a nil terminated comma separated list of substates.
    @see -addSubstate:
    @return Returns the receiver, to enable chaining-style programming
 */
- (YBState*)addSubstates:(YBState *)substates, ... NS_REQUIRES_NIL_TERMINATION;

/**
	The name of the receiver as set in -initWithName: or +stateWithName:
 */
@property (nonatomic, readonly) NSString *name;

/**
	YES if the state is currently active, NO if it is not.
    @see -[YBStatechart activateState:]
 */
@property (nonatomic, readonly) BOOL isActive;

/**
	The statechart that is associated with the receiver. It is automatically set when a rootState is assigned to the statechart, or when 
    substates are added thereafter using -[YBState addSubstate:]
    @see -[YBStatechart setRootState:]
    @see -[YBState addSubstate:]
 */
@property (nonatomic, readonly, weak) YBStatechart *statechart;

/**
	The superstate of the receiver. Will be nil if the state is the root state or if the receiver has
    not been added as substate yet.
    @see -[YBState addSubstate:]
 */
@property (nonatomic, readonly, weak) YBState *superstate;

/**
	The initialSubstate is the substate that will be activated when the receiver is activated. In case there are no or one substates,
    this value has no effect. In case there are more than one substates, this value is required before the statechart that the receiver
    is part of can be activated. Setting initialSubstate will implicitely add the assigned state as a substate if has not been added
    using -addSubstate: before.
    In case the useHistory propery is set to YES, historySubstate will be used to decide which substate will be made active, unless
    there is no previous substate (history) known.
 */
@property (nonatomic) YBState *initialSubstate;

/**
	Accessors for the last active substate. This is automatically set when the active state is changed using e.g. the -[YBStatechart activateState...] methods.
    @see useHistory
    @see -[YBStatechart activateState:]
 */
@property (nonatomic, readwrite, assign) YBState *historySubstate;

/**
	Set this property to YES if the receiver should store the active substate as it gets actived and make the stored substate
    active again as initial substate the next time the receiver becomes active. If no previously active substate has been stored,
    the initialSubstate property will be used. If substatesAreConcurrent is set to YES, this property is ignored.
 */
@property (nonatomic, assign, readwrite) BOOL useHistory;

/**
	If substates are orthogonal (substatesAreOrthogonal is set to YES), they can be active/inactive independent of one another.
    If they are not orthogonal (substatesAreOrthonogal is set to NO), only one of the substates is active at a time and the others
    will be inactive. Default to NO.
    @see -[YBStatechart activateState:] to activate a state in the statechart.
 */
@property (nonatomic, assign) BOOL substatesAreOrthogonal;

/**
	The direct substates of the receiver that have been added.
    @see -[YBState addSubstate:]
 */
@property (nonatomic, readonly) NSSet *substates;

@end


#if DEBUG
@interface YBStatechart (Debugging)
/**
	Validates if the statechart is fully-defined. Prints the parameters that need to be defined in order to make the statechart fully-defined (e.g. missing `initialSubstate` values).
	@returns YES if the statechart is fully-defined, or NO if there are parameters missing.
 */
- (BOOL)debugValidate;
@end
#endif