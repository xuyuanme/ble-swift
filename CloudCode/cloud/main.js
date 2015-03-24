var delayUntil;
var delayPromise;

var _delay = function () {
	if (Date.now() >= delayUntil) {
		delayPromise.resolve();
		return;
	} else {
		process.nextTick(_delay);
	}
}

var delay = function(delayTime) {
	delayUntil = Date.now() + delayTime;
	delayPromise = new Parse.Promise();
	_delay();
	return delayPromise;
};

var delayFoo = function(){
	console.log("1");
};

Parse.Cloud.define("test", function(request, response) {
	delay(5000).then(delayFoo);
	console.log("2");
	// response.success();
});

Parse.Cloud.job('scandiscovery', function(request, status) {
	const interval = 30 * 60 * 1000; // 30 min
	var Discovery = Parse.Object.extend("Discovery");
	var discoveryQuery = new Parse.Query(Discovery);
	discoveryQuery.notEqualTo("scanned", true);
	discoveryQuery.notEqualTo("derived", "flipped");
	var d = new Date();
	var timeNow = d.getTime();
	var timeThen = timeNow - interval;
	var queryDate = new Date();
	queryDate.setTime(timeThen);
	discoveryQuery.greaterThanOrEqualTo("updatedAt", queryDate);
	discoveryQuery.find({
		success: function(results) {
			for (var i = 0; i < results.length; i++) { 
				var discovery = results[i];
				// switch fromDevice and discoveredDevice
				var switchedDiscovery = new Discovery();
				switchedDiscovery.set("fromDevice", discovery.get("discoveredDevice"));
				switchedDiscovery.set("discoveredDevice", discovery.get("fromDevice"));
				switchedDiscovery.set("location", discovery.get("location"));
				switchedDiscovery.set("derived", "flipped");
				switchedDiscovery.save();
				discovery.set("scanned", true);
				discovery.save();
			}
			status.success("Scan discovery job completed successfully.");
		},
		error: function(error) {
			status.error(error);
		}
	});
});

// Before saving Discovery
Parse.Cloud.beforeSave("Discovery", function(request, response) {
	if (request.object.get("derived") && !request.object.id) { // if it is new derived data
		const interval = 2 * 60 * 1000; // 2 mins
		var Discovery = Parse.Object.extend("Discovery");
		var discoveryQuery = new Parse.Query(Discovery);
		discoveryQuery.equalTo("fromDevice", request.object.get("fromDevice"));
		discoveryQuery.equalTo("discoveredDevice", request.object.get("discoveredDevice"));
		var d = new Date();
		var timeNow = d.getTime();
		var timeThen = timeNow - interval;
		var queryDate = new Date();
		queryDate.setTime(timeThen);
		discoveryQuery.greaterThanOrEqualTo("updatedAt", queryDate);
		discoveryQuery.find({
			success: function(results) {
				if (results.length > 0) {
					response.error("Already exists this discovery");
				} else {
					response.success();
				}
			},
			error: function(error) {
				response.error(error);
			}
		});
	} else {
		response.success();
	}
});

// Push after saving new discovery
Parse.Cloud.afterSave("Discovery", function(request) {
	if(!request.object.get("pushed")) {
		Parse.Cloud.run('pushdiscovery', { fromDevice: request.object.get("fromDevice").id, discoveredDevice: request.object.get("discoveredDevice").id }, {
			success: function(msg) {
				console.log(msg);
				request.object.set("pushed", true);
				request.object.save();
				// Push the counterparty
				// delay does not work in afterSave, don't know the reason yet
				// delay(1000).then(delayPushDiscovery(request.object.get("discoveredDevice").id, request.object.get("fromDevice").id));
				console.log("Introduce friends of " + request.object.get("fromDevice"));
				const interval = 2 * 60 * 1000; // 2 mins
				var Discovery = Parse.Object.extend("Discovery");
				var discoveryQuery = new Parse.Query(Discovery);
				discoveryQuery.equalTo("fromDevice", request.object.get("fromDevice"));
				var d = new Date();
				var timeNow = d.getTime();
				var timeThen = timeNow - interval;
				var queryDate = new Date();
				queryDate.setTime(timeThen);
				discoveryQuery.greaterThanOrEqualTo("updatedAt", queryDate);
				discoveryQuery.find({
					success: function(results) {
						for (var i = 0; i < results.length; i++) { 
							var discovery = results[i];
							if (discovery.get("discoveredDevice").id != request.object.get("discoveredDevice").id) {
								var switchedDiscovery = new Discovery();
								switchedDiscovery.set("fromDevice", request.object.get("discoveredDevice")); // Introduce friend A
								switchedDiscovery.set("discoveredDevice", discovery.get("discoveredDevice")); // to know friend B
								switchedDiscovery.set("location", request.object.get("location"));
								switchedDiscovery.set("derived", request.object.get("fromDevice").id);
								switchedDiscovery.save();
							}
						}
					},
					error: function(error) {
						console.error(error);
					}
				});
			},
			error: function(error) {
				console.error(error);
			}
		});
	}
});

var delayPushDiscovery = function(fromDevice, discoveredDevice) {
	console.log("Push after delay");
	Parse.Cloud.run('pushdiscovery', {fromDevice: fromDevice, discoveredDevice: discoveredDevice}, {
		success: function(msg) {
			console.log(msg);
		},
		error: function(error) {
			console.error(error);
		}
	});
}

// Push by a discovery
Parse.Cloud.define("pushdiscovery", function(request, response) {
	const interval = 2 * 60 * 1000; // 2 mins
	var discoveryQuery = new Parse.Query("Discovery");
	var fromDevice = new Parse.Installation();
	fromDevice.id = request.params.fromDevice;
	discoveryQuery.equalTo("fromDevice", fromDevice);
	var discoveredDevice = new Parse.Installation();
	discoveredDevice.id = request.params.discoveredDevice;
	discoveryQuery.equalTo("discoveredDevice", discoveredDevice);
	discoveryQuery.equalTo("pushed", true);
	var d = new Date();
	var timeNow = d.getTime();
	var timeThen = timeNow - interval;
	var queryDate = new Date();
	queryDate.setTime(timeThen);
	discoveryQuery.greaterThanOrEqualTo("updatedAt", queryDate);
	discoveryQuery.find({
		success: function(results) {
			if(results.length > 0) {
				response.error("It has already been pushed");
			} else {
				var usernameQuery = new Parse.Query(Parse.Installation);
				usernameQuery.get(request.params.discoveredDevice, { // query username by installation's user
					success: function(installation) {
						var user = installation.get("user");
						user.fetch({
							success: function(user) {
								var username = user.get("username");
								Parse.Cloud.run('pushdevice', {objectId: request.params.fromDevice, message: 'Hi I\'m ' + username}, {
									success: function(msg) {
										response.success(msg);
									},
									error: function(error) {
										response.error(error);
									}
								});
							}, error: function(error) {
								response.error(error);
							}
						});
					},
					error: function(object, error) {
						response.error(error);
					}
				});
			}
		},
		error: function(error) {
			response.error(error);
		}
	});
});

// Push to a specific device
Parse.Cloud.define("pushdevice", function(request, response) {
	var pushQuery = new Parse.Query(Parse.Installation);
	pushQuery.equalTo('objectId', request.params.objectId);

	// Send push notification to query
	Parse.Push.send({
		where: pushQuery,
		data: {
			alert: request.params.message
		}
	}, {
		success: function() {
			response.success("Push sent successfully");
		},
		error: function(error) {
			response.error(error);
		}
	});
});

// Push to a specific user
Parse.Cloud.define("pushuser", function(request, response) {
	// Find users near a given location
	var userQuery = new Parse.Query(Parse.User);
	userQuery.equalTo("username", request.params.username);

	// Find devices associated with these users
	var pushQuery = new Parse.Query(Parse.Installation);
	pushQuery.matchesQuery('user', userQuery);

	// Send push notification to query
	Parse.Push.send({
		where: pushQuery,
		data: request.params.message
	}, {
		success: function() {
			response.success("Push sent successfully");
		},
		error: function(error) {
			response.error(error);
		}
	});
});


// Push to all iOS users
Parse.Cloud.define("pushios", function(request, response) {
	// Notification for iOS users
	var queryIOS = new Parse.Query(Parse.Installation);
	queryIOS.equalTo('deviceType', 'ios');

	Parse.Push.send({
		where: queryIOS,
		data: {
			alert: request.params.message
		}
	});
});
