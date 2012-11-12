YBStatechart
============

YBStatechart is a statechart framework. Statecharts are a formalized type of finite state machine, which resulted from [David Harel's research] [1] on software architecture design for aircraft systems in 1986. His [white paper article] [1] is well worth the (somewhat lengthy) read.

The statechart design pattern is also used in the SproutCore web front-end framework. They wrote [a blog article] [2] about statecharts compared to the model-view-controller pattern.

Contrived example
-----------------

A very simple example of a chart with only 2 substates:

	YBState *rootState = [YBState stateWithName:@"rootState"];
	YBState *loggedOut = [YBState stateWithName:@"loggedOut"];
    YBState *loggedIn = [YBState stateWithName:@"loggedIn"];
    
	[loggedIn onEnterState:^(YBState *_self) {
        // executed when loggedIn state is entered / activated
    }];
    
    [loggedIn onExitState:^(YBState *_self) {
        // executed when loggedIn state is exited / deactivated
    }];
    
    [loggedIn on:@"buttonPress" doBlock:^(YBState *_self) {
        // executed only when loggedIn is active
		// AND 
		// [statechart buttonPress] or [statechart dispatchEvent:@"buttonPress"] got called
    }];
	
    YBStatechart *statechart = [[YBStatechart alloc] init];
    statechart.rootState = rootState;
    [statechart activate];

A state can be activated by calling one of the `-activateState...:` methods on the statechart, e.g.:

	[statechart activateState:loggedIn];

Now the `statechart` object is able to respond to arbitrary Objective-C messages, which will be dispatched as "events" to all the active substates and their active substates, ... For example:

	[statechart buttonPress];
	
This will call the block handlers associated with the named event `buttonPress`, but only on states that are active at this moment.

For more useful examples, please read [David Harel's white paper] [1].

Installation
------------
[CocoaPods][3] is the recommended way to install YBStatechart

Example podfile:

	pod 'YBLStatechart', '1.0.0'


License
-------
YBLStatechart is licensed under the [Apache Software License, 2.0 ("Apache 2.0")][4]


[1]: http://www.wisdom.weizmann.ac.il/~harel/SCANNED.PAPERS/Statecharts.pdf
[2]: http://blog.sproutcore.com/statecharts-in-sproutcore/
[3]: http://cocoapods.org
[4]: http://www.apache.org/licenses/LICENSE-2.0