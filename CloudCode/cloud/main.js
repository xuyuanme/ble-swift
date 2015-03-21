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