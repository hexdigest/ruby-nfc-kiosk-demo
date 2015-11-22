require 'sinatra'
require 'sinatra-websocket'
require './nfc_thread'

set :server, 'thin'
set :thread, nil

queue = Queue.new
nfc_thread(queue)

get '/' do
  if !request.websocket?
    erb :index
  else
    request.websocket do |ws|
      ws.onopen do
        queue << ws
      end

      ws.onmessage do |msg|
        queue << msg
      end
    end
  end
end

__END__
@@ index
<!DOCTYPE html>
<html lang="en">
	<head>
		<link href="/css/bootstrap.css" rel="stylesheet" />
		<link href="/css/bootstrap-responsive.css" rel="stylesheet" />
		<link href="/css/docs.min.css" rel="stylesheet" />
	</head>

  <body>
		<div class="bs-docs-header">
			<div class="container">
				<h1>Ruby NFC kiosk demo</h1>
				<p><a href="https://github.com/hexdigest/ruby-nfc-kiosk-demo">https://github.com/hexdigest/ruby-nfc-kiosk-demo</a></p>
 			</div>
		</div>

		<div class="container">
			<div class="row">
				<div class="span6">
					<h1 id="greetings">Tap your card please</h1>
				</div>
				<div class="span6" id="msgs"></div>
    	</div>

      <div class="row" id="cardinfo">
    		<div class="span2">
	    		<img src="" width="320" height="320" id="photo"/>
   			</div>
        <div class="span2" id="info">
     			<form id="form">
            <div class="form-group">
                <label for="name">Name</label>
                <input type="text" class="form-control" name="name" id="name" placeholder="Name">
            </div>
            <div class="form-group">
                <label for="balance">Balance</label>
                <input type="text" class="form-control" name="balance" id="balance" placeholder="Balance">
            </div>
            <div class="form-group">
                <label for="year">Year</label>
                <input type="text" class="form-control" name="year" id="year" placeholder="Year">
            </div>
            <div class="form-group">
                <label for="month">Month</label>
                <input type="text" class="form-control" name="month" id="month" placeholder="Month">
            </div>
            <div class="form-group">
                <label for="day">Day</label>
                <input type="text" class="form-control" name="day" id="day" placeholder="Day">
            </div>
          </form>

          <button type="submit" class="btn btn-primary" id="submit">Submit</button>
   			</div>
    	</div>
		</div>

    <script src="/js/bootstrap.min.js"></script>
    <script src="/js/jquery-2.1.4.min.js"></script>
  </body>

  <script type="text/javascript">
    function show(cardInfo) {
      for (var field in cardInfo) {
          if (cardInfo.hasOwnProperty(field)) {
            $("#" + field).val(cardInfo[field])
          }
      }

      $("#photo").attr("src", "/img/" + cardInfo.name + ".jpg")
      $("#cardinfo").show()
      $("#greetings").text("Card owner information")
    }

    var ws = null

    function createSocket() {
      ws = new WebSocket('ws://' + window.location.host + window.location.pathname)

      ws.onmessage = function(m) { 
        s = JSON.parse(m.data)
        if (typeof(s.error) !== 'undefined') {
          alert(s.error)
        } else {
          show(s)
        }
      };

      ws.onclose = function()  {
        $("#greetings").text("Tap your card please")
        $("#cardinfo").hide()

        setTimeout(createSocket, 300)
      };
    }


    $(document).ready(function(){
      $("#cardinfo").hide()

      $("#submit").click(function(){
        var o = {};
        $("#form").serializeArray().map(function(x){o[x.name] = x.value;});
        o = JSON.stringify(o, null, 2)
        ws.send(o)
      })

      createSocket()
      
    })
  </script>
</html>
