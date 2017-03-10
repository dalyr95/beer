<beer>
	<div class="container { confirmed: state.confirmed }">
		<ul>
			<virtual if={ !state.confirmed } each={ name, i in this.state.pubs }>
				<li class="card { selected: this.state.card === name }" onclick={ selected.bind(this, name) }><span>{ name }</span></li>
			</virtual>
			<virtual if={ state.confirmed } each={ name, i in this.state.pubs }>
				<li class="card { selected: this.state.card === name }"><span>{ name }</span></li>
			</virtual>
		</ul>
	</div>

	<div class="users">
		<h2>Drinkers</h2>
		<ul>
			<li each={ value, i in state.clients }>{ value.name }</li>
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
			confirmed: false
		};

		this.on('mount', function() {
			socket.on('joined', function(room, clientId, clients) {
				this.state.clients = clients;

				this.update();
			}.bind(this));

			socket.on('left', function(room, clientId, clients) {
				this.state.clients = clients;

				this.update();
			}.bind(this));
		});

		var timers, row;

		this.selected = function(card, e){

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

					this.state.confirmed = true;
					this.state.pubs = row;
					riot.update();

				} else {
					this.state.card = null;
					this.update();
				}
			}.bind(this), 100);
		}
	</script>

	<style>
		.container {
			padding: 40px;
			width: 1050px;
			margin: 0 auto;
		}

		.container ul {
		    display: flex;
		    flex-direction: row;
		    justify-content: space-around;
		    flex-wrap: wrap;
		}

		.confirmed .card {
			pointer-events: none;
		}

		.card {
			border-radius: 5px;
			border: 1px solid #666;
			cursor: pointer;
			height: 326px;
			margin-bottom: 10px;
			position: relative;
			text-align: center;
			width: 233px;
		}

		.card.selected {
			box-shadow: 0 0 4px 2px red;
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
			padding: 4px;
			border-bottom: 1px solid #ccc;
		}
	</style>
</beer>