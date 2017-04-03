<beer>
	<div class="container { confirmed: state.confirmed }">
		<ul>
			<virtual if={ !state.confirmed } each={ name, i in this.state.pubs }>
				<li class="card { selected: this.state.card === name }" onclick={ selected }><span>{ name }</span></li>
			</virtual>
			<virtual if={ state.confirmed === true && state.shuffling === false } each={ name, i in this.state.pubs }>
				<li class="flip-container { hover: state.flip || state.pick }" onclick={ pickCard }>
					<div class="flipper">
						<div class="card front { selected: this.state.card === name }"><span>{ name }</span></div>
						<div class="card back"></div>
					</div>
				</li>
			</virtual>

			<virtual if={ state.confirmed === true && state.shuffling === true } each={ name, i in this.state.pubs }>
				<li class="card back" onclick={ selected }><span>{ name }</span></li>
			</virtual>
		</ul>
	</div>

	<div class="users">
		<h2>Drinkers</h2>
		<ul>
			<li each={ value, i in state.clients }>{ value.name }</li>
		</ul>

		<h2>Selected</h2>
		<ul>
			<li each={ value, i in state.clients } if={ value.pub }>{ value.pub } ({ value.name })</li>
		</ul>
	</div>

	<script>
		window.tag = this;

		this.state = {
			card: null,
			pubs: [
				'King & Queen',
				'Green Man',
				'Jack Horner',
				'Rising Sun',
				'Draft House',
				'Yorkshire Grey',
				'The Crown & Sceptre',
				'One Tun',
				'Fitzroy Tavern',
				'Kings Arms',
				'Tower Tavern',
				'The Hope',
				'The Carpenters Arms',
				'The Lukin',
				'Duke of York',
				'Fitzrovia',
				'TCR Lounge Bar',
				'Marlborough Arms',
				'The Lucky Pig',
				'The Court'
			],
			clients: [],
			confirmed: false,
			shuffling: false
		};

		var $shuffleStyle = document.getElementById('shuffle-style');

		this.on('mount', function() {
			socket.on('joined', function(room, clientId, clients) {
				this.state.clients = clients;

				this.update();
			}.bind(this));

			socket.on('left', function(room, clientId, clients) {
				this.state.clients = clients;

				this.update();
			}.bind(this));

			socket.on('selection', function(room, clientId, clients, selection) {
				this.state.clients 	= clients;
				this.state.round 	= selection;

				this.update();
			}.bind(this));
		});

		var timers, row;

		this.selected = function(e){
			var card = e.currentTarget.innerText;

			if (this.state.card === card) {
				this.state.card = null;
			} else {
				this.state.card = card;
			}

			var target = e.currentTarget;

			clearInterval(timers);
			timers = setTimeout(function() {
				if (window.confirm('Are you sure you want to go to ' + card + '?')) {
					row = [];

					var top = target.getBoundingClientRect().top;

					[].slice.call(document.querySelectorAll('.card')).forEach(function(card) {
						if (top === card.getBoundingClientRect().top) {
							row.push(card.innerText.trim());
						}
					});

					this.state.confirmed 	= true;
					this.state.pubs 		= row;

					this.one('updated', function() {
						setTimeout(function() {
							this.state.flip = true;
							this.update();
							setTimeout(function() {
								this.one('updated', function() {
									this.shuffle();
								});
								this.state.shuffling = true;
								this.update();
							}.bind(this), 2000);
						}.bind(this), 3000);
					});

					this.update();

					socket.emit('selected', card);
				} else {
					this.state.card = null;
					this.update();
				}
			}.bind(this), 100);
		}.bind(this);

		this.shuffle = function() {
			this.state.shuffling 	= true;
			var initial 			= true;
			var count 				= 0;

			var movement = function() {
				count++;

				$shuffleStyle.innerText = '';

				this.pack = {
					names: [],
					cards: []
				};

				[].slice.call(document.querySelectorAll('.card.back')).forEach(function(card) {
					this.pack.names.push((initial === true) ? btoa(card.innerText) : card.innerText);
					this.pack.cards.push(card);
				}.bind(this));

				initial = false;

				var a = Math.floor(Math.random() * (4));
				var b = Math.floor(Math.random() * (4));

				do {
					a = Math.floor(Math.random() * (4));
				} while(a === b);

				console.log(this.pack.cards[a], this.pack.cards[b]);

				var aPosition = this.pack.cards[a].getBoundingClientRect();
				var bPosition = this.pack.cards[b].getBoundingClientRect();

				$shuffleStyle.innerText = `
					.card:nth-child(${a + 1}) {
						background-color: red !important;
						transform: translate3d(${bPosition.left - aPosition.left}px,0,0);
					}
					.card:nth-child(${b + 1}) {
						background-color: green !important;
						transform: translate3d(${aPosition.left - bPosition.left}px,0,0);
					}

					.card {
						transition: transform 1s linear;
					}
				`;

				var aName = this.pack.names[a];
				var bName = this.pack.names[b];

				this.pack.names = this.pack.names.map(function(value, index) {
					if (index === a) { value = bName; }
					if (index === b) { value = aName; }

					return value;
				});

				console.log(JSON.stringify(this.pack.names));

				document.querySelector('.container').addEventListener('transitionend', function() {
					console.log(JSON.stringify(this.pack.names));

					this.state.pubs = JSON.parse(JSON.stringify(this.pack.names));

					this.one('updated', function() {
						$shuffleStyle.innerText = '';
						if (count < this.state.round * 4) {
							setTimeout(movement, 1000);
						} else {
							console.log('pick');
							this.state.shuffling 	= false;
							this.state.pick 		= true;
							this.update();
						}
					});

					this.update();
				}.bind(this), {
					passive: true,
					once: true
				});


			}.bind(this);

			movement();
		}.bind(this);

		pickCard = function(e) {
			if (this.state.pick === true) {
				var pick = atob(e.currentTarget.innerText);
				console.log(pick, this.state.card, (this.state.card === pick));

				[].slice.call(document.querySelectorAll('.card span')).forEach(function($el) {
					$el.innerText = atob($el.innerText);
				});

				this.state.pick = false;
				this.state.flip = false;
			}
		}
	</script>

	<style>
		.container {
			width: 1050px;
			margin: 0 auto;
		}

		.container ul {
			min-height: 100vh;
			padding: 40px;
		    align-items: center;
		    display: flex;
		    flex-direction: row;
		    flex-wrap: wrap;
		    justify-content: space-around;
		}

		.confirmed .card {
			pointer-events: none;
		}

		.card {
			border-radius: 5px;
			border: 1px solid #666;
			cursor: pointer;
			height: 331px;
			margin-bottom: 10px;
			position: relative;
			text-align: center;
			width: 200px;
		}

		.card.selected {
			box-shadow: inset 0 0 4px 2px red;
		}

		.card.back {
			background-image: url('card.jpg');
			background-size: 90%;
			background-position: 50%;
			background-repeat: no-repeat;
			color: transparent;
		}

		.card span {
			position: absolute;
			top:  50%;
			left: 50%;
			transform: translate(-50%);
		}

		.users {
			border-left: 1px solid #ccc;
			background-color: #fff;
			height: 100vh;
			padding: 20px;
			position: fixed;
			right: 0;
			top: 0;
		}

		.users ul {
			margin: 10px 0;
		}

		.users li {
			border-bottom: 1px solid #ccc;
			padding: 4px;
			text-transform: capitalize;
		}


		/* entire container, keeps perspective */
		.flip-container {
			perspective: 1000px;
		}
		/* flip the pane when hovered */
		.flip-container.hover .flipper {
			transform: rotateY(180deg);
		}

		.flip-container, .front, .back {
			height: 331px;
			width: 200px;
		}

		/* flip speed goes here */
		.flipper {
			transition: 0.6s;
			transform-style: preserve-3d;

			position: relative;
		}

		/* hide back of pane during swap */
		.flip-container .front, .flip-container .back {
			backface-visibility: hidden;

			position: absolute;
			top: 0;
			left: 0;
		}

		/* front pane, placed above back */
		.flip-container .front {
			z-index: 2;
			/* for firefox 31 */
			transform: rotateY(0deg);
		}

		/* back, initially hidden pane */
		.flip-container .back {
			transform: rotateY(180deg);
		}
	</style>
</beer>