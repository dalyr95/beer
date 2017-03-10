'use strict';

var os = require('os');
var nodeStatic = require('node-static');
var http = require('http');
var socketIO = require('socket.io');

var fileServer = new(nodeStatic.Server)();
var app = http.createServer(function(req, res) {
  fileServer.serve(req, res);
}).listen(8888);

var clients = [];
var room = 'beer';

var io = socketIO.listen(app);
io.sockets.on('connection', function(socket) {
  // convenience function to log server messages on the client
  function log() {
    var array = ['Message from server:'];
    array.push.apply(array, arguments);
    socket.broadcast.emit('log', array);
  }

  socket.on('message', function(message) {
    log('Client said: ', message);
    // for a real app, would be room-only (not broadcast)
    socket.broadcast.emit('message', message);
  });

  socket.on('create or join', function(name) {

    log('Received request from ' + name + ' join room');

    var numClients = io.engine.clientsCount;
    log('Room ' + room + ' now has ' + numClients + ' client(s)');

    clients.push({
      name: name,
      socket: socket.id
    });

    if (numClients === 1) {
      socket.join(room);
      log('Client ID ' + name + ' created room ' + room);
      io.sockets.in(room).emit('joined', name, socket.id, clients);

    } else {
      log('Client ID ' + name + ' joined room ' + room);
      io.sockets.in(room).emit('join', name);
      socket.join(room);
      io.sockets.in(room).emit('joined', name, socket.id, clients);
    }

    log('Clients', clients);
  });

  socket.on('ipaddr', function() {
    var ifaces = os.networkInterfaces();
    for (var dev in ifaces) {
      ifaces[dev].forEach(function(details) {
        if (details.family === 'IPv4' && details.address !== '127.0.0.1') {
          socket.emit('ipaddr', details.address);
        }
      });
    }
  });

  socket.on("disconnect", function(){
    var leaver = {};

    clients = clients.filter(function(client) {
      if (client.socket === socket.id) {
        leaver = client;
        return false;
      }
      return true;
    });

    io.sockets.in(room).emit('left', leaver.name, leaver.socket, clients);
  });

});
