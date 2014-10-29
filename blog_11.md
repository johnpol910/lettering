# Zero to Angular in Seconds - DataSync Edition

Welcome back to our blog series about how to get started quickly with
AngularJS using the PubNub AngularJS library. In a [recent episode](http://www.pubnub.com/blog/angularjs-101-from-zero-to-angular-in-seconds/),
we covered a tiny but powerful example of how to get started with
a real-time Angular Chat application in less than 100 lines of code.

The code for today's example is available here:

* https://github.com/pubnub/angular-js/blob/master/app/examples/datasync_1.0.x.html

In _this_ installment we're looking at PubNub's brand new DataSync BETA
feature, which lets your app integrate with live-streaming objects.
The advantage of DataSync with PubNub is that it provides live updates
AND frees your app from the need for back-end persistence, making it much
easier to get up and running. Thanks to the magic of Angular, it's
super easy to make this happen with minimal code tweaks!

First off, let's take a look at the situations where you might take
advantage of DataSync:

* You're using one object per Stock in a [stock-updates app](http://rtstock.co/)
* You are building an Internet of Things app, and would like devices to publish their state directly
* In a game or collaboration app, you'd like to represent your entities & game state using live objects
* Just about anything you'd do with state change events, but modeling using the *complete latest current state* instead of change updates!

So, now that you know you want to try out DataSync, how do you
do it? It's pretty easy with the PubNub angular application.

# Step 1: Get Your Includes On

Setup of the PubNub Angular library is pretty much the same as with the original Zero-to-Angular example:

```
<!doctype html>
<html lang="en">
<head>
<script src="//ajax.googleapis.com/ajax/libs/angularjs/1.0.8/angular.min.js"></script>
<script src="https://rawgit.com/pubnub/javascript/feature-pt74838232-2/web/pubnub.min.js"></script>
<script src="https://rawgit.com/pubnub/pubnub-angular/v1.2.0-beta.3/lib/pubnub-angular.js"></script>
<link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.0.2/css/bootstrap.min.css">
</head>
<body>
```

What does all this stuff do?

* angular.min.js : that AngularJS goodness we all know and love
* pubnub.min.js : the main PubNub communication library for JavaScript
* pubnub-angular.js : bring in the official PubNub SDK for AngularJS
* bootstrap.min.css : bring in the bootstrap styles

Once these are all set, you’re good to start coding!

NOTE: at the time of this writing, PubNub DataSync is in private BETA. You'll
need to request a DataSync-enabled publish and subscribe key here!

* http://www.pubnub.com/how-it-works/data-sync/

# Step 2: Set Up Your HTML Layout and Dynamic Content

Setup of the content DIV is the same as with the original Zero-to-Angular example:

```
<div class="container" ng-app="DataSyncApp" ng-controller="DataSyncController">
```

The two angular attributes operate as follows:

* The `ng-app` directive tells Angular which application to wire up
* The `ng-controller` directive tells Angular which controller to wire up

```
<div class="row">
<h1>DataSync</h1>
<table>
<tr>
  <td><h4>Database Name</h4><input ng-model="object_id"></td>
  <td><h4>Path</h4><input ng-model="path"></td>
  <td><h4>Absolute Path</h4><input ng-model="absolute_path" readonly></td>
</tr>
```

The key things to note about this code are:

* We care about 2 scope attibutes: `object_id` and `path`
* The `object_id` is the object id we're using with DataSync
* The `path` is the path we're using with DataSync (in the case of a nested attribute)
* The `absolute_path` is a computed attribute we maintain with a $scope.$watch function (stay tuned!)

This is just setting up the ID's well need to tell DataSync what we're talking about. Not too bad, right?

```
<tr>
  <td colspan=3>
    <button ng-click="get()">get</button>
    <button ng-click="set()">set</button>
    <button ng-click="merge()">merge</button>
    <button ng-click="remove()">remove</button>
    <button ng-click="watch()">watch</button>
    <button ng-click="sync()">sync</button>
  </td>
</tr>
```

Here, we're setting up a collection of buttons to perform actions from the controller scope.

* `get()` retrieves the current value of the object (or recursive path, if provided)
* `set()` sets the current value of the object to the absolute value `{"isAwesome":true}`
* `merge()` merges in a single attribute update to the object - in this case, we'll set `time` to the current date String
* `remove()` removes all attributes from the object
* `watch()` sets up a "live stream" of update events from PubNub into the scope via $rootScope.$broadcast
* `sync()` is the *most awesome* operation - it retrieves the current value of the object and keeps it updated in real time
* NOTE: only one of `watch()` or `sync()` may be active at a time - don't mix and match or the application events can get messed up

```
<tr>
  <td colspan=3>
    <div class="well">
      {{theObj}}
    </div>
  </td>
</tr>
```

That just displays the current value of the object as a JSON blob - nothing special there!


# Step 3: JavaScript – Where the Magic Happens

Just like the previous blog entry, let's wrap up by taking a stroll through
the JavaScript to see what's happening. You'll recognize a bunch from last time:

```
var app = angular.module('DataSyncApp', ["pubnub.angular.service"]);

app.controller('DataSyncController', ['$scope', 'PubNub', function($scope, PubNub) {
  PubNub.init({
    publish_key   : "pub-c-YOURPUBKEY", // NOTE: app key must be enabled for DataSync BETA!
    subscribe_key : "sub-c-YOURSUBKEY", // NOTE: app key must be enabled for DataSync BETA!
    origin        : "pubsub-beta.pubnub.com"
  });
```

Just like last time, we:

* Declare an Angular module that matches our ng-app declaration
* Declare a Controller that matches our ng-controller declaration
* Intialize the PubNub object to establish a connection to the Cloud

The one *difference* is:

* Our `publish_key` and `subscribe_key` must be set up for the PubNub DataSync private BETA using the following link
* http://www.pubnub.com/how-it-works/data-sync/

That's pretty cool. Let's see what we have next.

```
var logit = function(prefix) { return function() {console.log(prefix, arguments);} }

$scope.object_id = 'foo';
$scope.path = '';
$scope.absolute_path = 'foo';

$scope.$watch('object_id + path', function(x) {
  $scope.absolute_path = $scope.object_id + ($scope.path ? "." + $scope.path : '');
});
```

The first line is just a little utility - it's a "function that returns a function".
So we pass in a prefix that we want to make part of the log, and the logit function
returns a new function that when called, logs the prefix plus the arguments to the
function. This is super useful for debugging!

The next few lines are setting up our important `$scope` variables.

* `object_id` is the DataSync object id
* `path` is the recursive path (for example, with get and set operations)
* `absolute_path` is a computed path with a watch based on the object_id and path attributes

```
$scope.theObj = null;

$scope.getObjDesc = function() {
  return {object_id : $scope.object_id, path : $scope.path};
}

$scope.get    = function() { PubNub.datasync_BETA.ngGet($scope.getObjDesc()).then(function(x) { $scope.theObj = x; }); }
$scope.remove = function() { PubNub.datasync_BETA.ngRemove({object_id:$scope.object_id}).then(logit('remove')); }
```

The important things about this code are:

* We initialize the scope object `theObj` to null (it's what we're displaying in the HTML)
* We create a helper function `getObjDesc` to create an object descriptor that includes the `object_id` and `path` from the scope
* We create a `get()` function that retrieves a $q promise for the new value using the `ngGet()` method, and, upon completion, sets `theObj` to that value
* We create a `remove()` function that retrieves a $q promise for the result using the `ngRemove()` method, and, upon completion, logs the server response

Pretty sweet! Now, how do we do updates? Whoa, looks like there's two ways!

```
$scope.set = function() {
  PubNub.datasync_BETA.ngSet({
    object_id : $scope.object_id,
    data : { 'isAwesome' : true }
  }).then(logit('set'));
}

$scope.merge = function() {
  PubNub.datasync_BETA.ngMerge({
    object_id : $scope.object_id,
    data : { 'time' : new Date() }
  }).then(logit('merge'));
}
```

Here we see the 2 data update operations, each of which takes an `object_id`
and the new replacement data as a `data` attribute.

* `ngSet()` - is awesome because it sets the entire value at the path
* `ngMerge()` - is even more awesome because it sets just the provided attributes at the path, leaving the rest alone

With these four operations (get, set, merge, remove), you can build a ton of
applications using PubNub as your data storage backend. But why stop there?
This is just the beginning - now we're going to wire up PubNub's real-time
update capabilities!

```
$scope.sync   = function() {
  $scope.theObj = PubNub.datasync_BETA.ngSync($scope.object_id);
}
```

This is my favorite operation - `ngSync()` returns an
empty object which is populated from the current value and
continuously updated in real-time. In addition, broadcast
events will be sent to the AngularJS $rootScope after each
real-time update!

This packs a *ton* of power into a tiny amount of code. When
was the last time you saw an entire global real-time update
infrastructure wired up in a single line of code?

Here's how to watch for update events:

```
$scope.$on(PubNub.datasync_BETA.ngObjPathEv('foo'),    logit('path_event'));
$scope.$on(PubNub.datasync_BETA.ngObjPathRecEv('foo'), logit('path_rec_event'));
$scope.$on(PubNub.datasync_BETA.ngObjDsEv('foo'),      logit('dstr_event'));
```

* `ngObjPathEv()` - returns the Angular event name for a given object_id and path
* `ngObjPathRecEv()` - returns the Angular event name for recursive updates to a given object_id and path
* `ngObjDsEv()` - returns the Angular event name for a given object_id (when transactions complete)

For advanced use cases, you may just want to watch for raw update
events: this is possible using the `ngWatch()` function. All you do
is call it with the object_id and path you care about, and update
events will be broadcast on the 3 different channels listed above.

```
$scope.watch  = function() { PubNub.datasync_BETA.ngWatch($scope.getObjDesc()); }
```

NOTE: at the time of writing of this blog entry, it was only possible
to use one of `sync()` or `watch()` at a time. Choose wisely! For me,
I'll probably stick to `sync()` - although there are use cases where
I need the power of `watch()` to get more detailed metadata about the
updates in addition to the state changes.

```
});
</script>
</body>
</html>
```

... And we're done! Hopefully this helped you get started with PubNub
DataSync and AngularJS without much trouble. Please keep
in touch, and give us a yell if you run into any issues!

