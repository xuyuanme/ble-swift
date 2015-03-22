// Push after saving new discovery
Parse.Cloud.beforeSave("Discovery", function(request, response) {
	Parse.Cloud.run('pushdiscovery', { fromDevice: request.object.get("fromDevice").id, discoveredDevice: request.object.get("discoveredDevice").id }, {
		success: function(msg) {
			request.object.set("pushed", true);
			response.success();
		},
		error: function(error) {
			console.error(error);
			// Even the push fails, the save is still successful
			response.success();
		}
	});
});

// Push by a discovery
Parse.Cloud.define("pushdiscovery", function(request, response) {
	var discoveredInstallationQuery = new Parse.Query(Parse.Installation);
	discoveredInstallationQuery.get(request.params.discoveredDevice, {
		success: function(installation) {
			var user = installation.get("user");
			user.fetch({
				success: function(user) {
					var username = user.get("username");
					var pushQuery = new Parse.Query(Parse.Installation);
					pushQuery.equalTo('objectId', request.params.fromDevice);

// Send push notification to query
Parse.Push.send({
	where: pushQuery,
	data: {
		alert: 'Hi I\'m ' + username
	}
}, {
	success: function() {
		var fromInstallationQuery = new Parse.Query(Parse.Installation);
		fromInstallationQuery.get(request.params.fromDevice, {
			success: function(installation) {
				var user = installation.get("user");
				user.fetch({
					success: function(user) {
						var username = user.get("username");
						var pushQuery = new Parse.Query(Parse.Installation);
						pushQuery.equalTo('objectId', request.params.discoveredDevice);

// Send push notification to query
Parse.Push.send({
	where: pushQuery,
	data: {
		alert: 'Hi I\'m ' + username
	}
}, {
	success: function() {
		response.success("Push sent successfully");
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