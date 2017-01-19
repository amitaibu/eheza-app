var elmApp = Elm.Main.fullscreen({
    accessToken : localStorage.getItem('accessToken') || '',
    hostname : window.location.hostname
});

elmApp.ports.accessTokenPort.subscribe(function(accessToken) {
    localStorage.setItem('accessToken', accessToken);
});


elmApp.ports.pusherKey.subscribe(function(appKey) {
  var pusher = new Pusher(appKey, {
    cluster: 'mt1'
  });

  var channelName = 'general';

  if (!pusher.channel(channelName)) {
      var channel = pusher.subscribe(channelName);

      var eventNames = [
        'patient__update',
      ];

      eventNames.forEach(function(eventName) {
        channel.bind(eventName, function (data) {
            // We wrap the data with some information which will
            // help us dispatch it on the Elm side
            var event = {
                eventType: eventName,
                data: data
            };
            elmApp.ports.pusherPatientMessages.send(event);
        });
      });
  }
});

Offline.on('down', function() {
    elmApp.ports.offline.send (true);
});

Offline.on('up', function() {
    elmApp.ports.offline.send (false);
});
