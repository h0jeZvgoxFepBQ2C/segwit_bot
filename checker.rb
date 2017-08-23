


require 'faye/websocket'
require 'eventmachine'
require 'json'


require 'cinch'

CHANNEL = "#blocktest"

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = [CHANNEL]
    c.nick = "segwit_block_bot"
  end

  on :message, /.*/ do |m|
    debug m.message
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
      if !data.nil? && !data["x"].nil? && !data["x"]["blockIndex"].nil?
        blockheight = data["x"]["blockIndex"].to_i
        activation = 481823
        diff = activation - blockheight
        exit 0 if diff < 0
        if diff == 0
          puts bot.channels.first.safe_send("!!!! LAST BLOCK MINED - HAPPY BIRTHDAY SEGWIT!!!!", true)
        else
          puts bot.channels.first.safe_send("Block #{blockheight} found! Only #{diff} to go! (Activation on block #{activation})", true)
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
