'use strict'

###
The JoinCtrl is responsible for collecting the username and calling the PubNub.init() method
when the "Join" button is clicked.
###
angular.module('PubNubAngularApp')
  .controller 'JoinCtrl', ($rootScope, $scope, $location, PubNub) ->
    $scope.data = {username:'Lettering ' + Math.floor(Math.random() * 1000)}

    $scope.join = ->
      $rootScope.data ||= {}
      $rootScope.data.username = $scope.data?.username
      $rootScope.data.uuid     = Math.floor(Math.random() * 1000000) + '__' + $scope.data.username

      #
      # NOTE! We include the secret & auth keys here only for demo purposes!
      #
      # In a real app, the secret key should be protected by server-only access, and
      # different/separate auth keys should be distributed by the server and used
      # for user authentication.
      #
      $rootScope.secretKey = if $scope.data.super then 'sec-c-MmIzMDAzNDMtODgxZC00YzM3LTk1NTQtMzc4NWQ1NmZhYjIy' else null
      $rootScope.authKey   = if $scope.data.super then 'ChooseABetterSecret' else null

      PubNub.init({
        subscribe_key : 'sub-c-d66562f0-62b0-11e3-b12d-02ee2ddab7fe'
        publish_key   : 'pub-c-e2b65946-31f0-4941-a1b8-45bab0032dd8'
        # WARNING: DEMO purposes only, never provide secret key in a real web application!
        secret_key    : $rootScope.secretKey
        auth_key      : $rootScope.authKey
        uuid          : $rootScope.data.uuid
        ssl           : true
      })
      
      $location.path '/lettering'
      
    $(".prettyprint")

###
The LetteringCtrl
###
angular.module('PubNubAngularApp')
  .controller 'LetteringCtrl', ($rootScope, $scope, $location, $timeout, PubNub) ->
    $location.path '/join' unless PubNub.initialized()
    
    ### Use a "control channel" to collect channel creation messages ###
    $scope.controlChannel = '__controlchannel'
    $scope.lettering_content = $(".lettering-content")
    $scope.objects = []
    $scope.scores = []
    $scope.me_score = 0

    $scope.occur_object = () ->
      if $scope.objects.length > 50
        return
      width = $($scope.lettering_content).width()
      height = $($scope.lettering_content).height()
      pos_x = Math.floor(Math.random() * width)
      obj_string = window.letters[Math.floor(Math.random() * window.letters.length )]
      $scope.publish_object pos_x, obj_string

    $scope.generate_id = () ->
      return Math.floor(Math.random() * 100 ) + "_" + Math.floor(Math.random() * 100 ) + "_" + Math.floor(Math.random() * 100 )

    $scope.publish_object = (posx, obj_string ) ->
      if !$scope.data
        return
      id = $scope.generate_id()
      return unless $scope.selectedChannel
      PubNub.ngPublish {channel: $scope.selectedChannel, message:{type:"object", user:$scope.data.username, id:id, x:posx, y:0, string:obj_string } }
      return

    $scope.start_timer_for_obj = () ->
      user_count = 1
      if ($scope.users )
        user_count = $scope.users.length
      time_interval = Math.floor(Math.random() * 2000 * user_count )
      $scope.occur_object()
      $timeout ->
         $scope.start_timer_for_obj()
      , time_interval

    $scope.start_timer_for_obj()

    $scope.start_timer_for_animation = () ->
      i = 0
      while i < $scope.objects.length
        $scope.objects[i].y = $scope.objects[i].y - 3
        if ($scope.objects[i].y < -30 )
          $scope.objects.splice i, 1
        i++
      $timeout ->
         $scope.start_timer_for_animation()
      , 100

    $scope.start_timer_for_animation()

    $scope.refresh_score = (username, score ) ->
      i = 0
      flag = false
      while i < $scope.scores.length 
        if username == $scope.scores[i].user
          flag = true
          if score != 1.5
            $scope.scores[i].score = score
          break
        i++
      if flag == false
        tmp_obj = new Object()
        tmp_obj.user = username
        tmp_obj.score = 0
        $scope.scores.push tmp_obj
      return

    $scope.submit_lettering = () ->
      flag = false
      tmp_id = ""
      i = 0
      while i < $scope.objects.length
        if ($scope.objects[i].string == $scope.me_letter )
          $scope.me_score = $scope.me_score + $scope.me_letter.length
          tmp_id = $scope.objects[i].id
          flag = true
          break
        i++
      if flag == false
        $scope.me_score = $scope.me_score - $scope.me_letter.length
      $scope.publish_letter $scope.me_score, tmp_id
      $scope.me_letter = ''

    $scope.publish_letter = (score, id ) ->
      PubNub.ngPublish {channel: $scope.selectedChannel, message:{type:"letter", user:$scope.data.username, id: id, score: score }}

    $scope.update_score = () ->
      i = 0
      while i < $scope.scores.length
        if !$scope.is_exists_user $scope.scores[i].user
          $scope.scores.splice i, 1
        i++

    $scope.is_exists_user = (username) ->
      if !$scope.users
        return false
      tmp_flag = false;
      i = 0
      while i < $scope.users.length
        if $scope.users[i] == username
          tmp_flag = true;
          break;
        i = i + 1
      return tmp_flag

    ### Select a channel to display presence state ###
    $scope.subscribe = (channel) ->
      console.log 'subscribe', channel
      return if channel == $scope.selectedChannel
      PubNub.ngUnsubscribe { channel: $scope.selectedChannel } if $scope.selectedChannel
      $scope.selectedChannel = channel

      PubNub.ngSubscribe {
        channel: $scope.selectedChannel
        auth_key: $scope.authKey
        error: -> console.log arguments
      }
      $rootScope.$on PubNub.ngPrsEv($scope.selectedChannel), (ngEvent, payload) ->
        $scope.$apply ->
          userData = PubNub.ngPresenceData $scope.selectedChannel
          newData  = {}

          $scope.users    = PubNub.map PubNub.ngListPresence($scope.selectedChannel), (x) ->
            newX = x
            if x.replace
              newX = x.replace(/\w+__/, "")
            if x.uuid
              newX = x.uuid.replace(/\w+__/, "")
            newData[newX] = userData[x] || {}
            $scope.refresh_score newX, 1.5
            newX
          $scope.publish_letter $scope.me_score, ""
          $scope.update_score()
          $scope.userData = newData

      PubNub.ngHereNow { channel:$scope.selectedChannel }
  
      $rootScope.$on PubNub.ngMsgEv($scope.selectedChannel), (ngEvent, payload) ->
        obj = payload.message
        $scope.$apply ->
          if obj.type == "object"
            obj.y = $($scope.lettering_content).height()
            $scope.objects.push obj
          else if obj.type == "letter"
            $scope.remove_letter obj.id, obj.score, obj.user
          return

    $scope.remove_letter = (id, score, user ) ->
      if id == ""
        $scope.change_score user, score
        return
      i = 0
      while i < $scope.objects.length
        if ($scope.objects[i].id == id )
          $scope.change_score user, score
          $scope.objects.splice i, 1
          break
        i++

    $scope.change_score = (user, score) ->
      i = 0
      while i < $scope.scores.length
        if ($scope.scores[i].user == user )
          $scope.scores[i].score = score
          break
        i++

    ### When controller initializes, subscribe to retrieve channels from "control channel" ###
    PubNub.ngSubscribe { channel: $scope.controlChannel }

    ### Register for channel creation message events ###
    $rootScope.$on PubNub.ngMsgEv($scope.controlChannel), (ngEvent, payload) ->
      $scope.$apply -> $scope.channels.push payload.message if $scope.channels.indexOf(payload.message) < 0

    $scope.subscribe 'WaitingRoom'