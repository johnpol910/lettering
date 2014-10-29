'use strict'

angular.module('PubNubAngularApp', ["pubnub.angular.service"])
  .config ($routeProvider) ->
    $routeProvider
      .when '/join',
        templateUrl: 'views/join.html'
        controller: 'JoinCtrl'
      .when '/lettering',
        templateUrl: 'views/lettering.html'
        controller: 'LetteringCtrl'
      .otherwise
        redirectTo: '/join'
