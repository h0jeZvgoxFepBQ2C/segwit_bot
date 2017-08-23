


require 'faye/websocket'
require 'eventmachine'
require 'json'


require 'cinch'

CHANNEL = "##uasf"

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = [CHANNEL]
    c.nick = "segwit_block_bot"
  end

  on :message, "hello blockbot" do |m|
    m.reply "Hello, #{m.user.nick}"
  end
end

Thread.new do
  bot.start
end

EM.run {
  ws = Faye::WebSocket::Client.new('wss://ws.blockchain.info/inv')

  ws.on :open do |event|
    p [:open]
    # ws.send('{"op":"unconfirmed_sub"}')
    ws.send('{"op":"blocks_sub"}')
  end

  ws.on :message do |event|
    if bot.channels.size > 0
      p [:message, JSON.parse(event.data)]

      data = JSON.parse(event.data) rescue []
      if !data.nil? && !data["x"].nil? && !data["x"]["height"].nil?
        blockheight = data["x"]["height"].to_i
        activation = 481823
        diff = activation - blockheight
        puts "DIFF #{diff}"
        exit 0 if diff < (-1)
        begin
          if diff == 0
            puts bot.channels.first.safe_send(":boom: :boom: :rocket: :tada: :tada: :tada: *LAST PRE-SEGWIT BLOCK MINED - SEGWIT WILL BECOME ACTIVE WITH THE NEXT BLOCK!!!* :tada: :tada: :tada:", true)
          elsif diff == 1
            puts bot.channels.first.safe_send(":boom: :boom: :rocket: :tada: :tada: :tada: *SEGWIT IS NOW ACTIVE!!!* :tada: :tada: :tada: *HAPPY BIRTHDAY SEGWIT!!!!* :tada: :tada: :tada:", true)
          else
            puts bot.channels.first.safe_send(":tada: Block #{blockheight} found! Only #{diff} blocks to go! (activation on block #{activation+1})", true)
          end
        rescue => e
          puts bot.channels.first.safe_send("Exception: #{e} #{data}", true)
        end
      else
        puts  bot.channels.first.safe_send("Found: #{data}", true)
      end
    end
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
