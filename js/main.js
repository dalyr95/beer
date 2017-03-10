'use strict';

var isInitiator;

var name = prompt("Enter name:");

var room = 'beer';

var socket = io.connect();
console.log(name);
if (room !== "") {
  console.log('Message from client: ' + name + ' asking to join room');
  socket.emit('create or join', name);
}

socket.on('created', function(room, clientId) {
  isInitiator = true;
});

socket.on('ipaddr', function(ipaddr) {
  console.log('Message from client: Server IP address is ' + ipaddr);
});

socket.on('joined', function(room, clientId, clients) {
	console.log(room, clientId, clients);
  isInitiator = false;
});

socket.on('log', function(array) {
  console.log.apply(console, array);
});