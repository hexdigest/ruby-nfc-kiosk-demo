require 'ruby-nfc'
require 'thread'
require 'json'

require './card_info'


def nfc_thread(queue)
	Thread.new do
		reader = NFC::Reader.all.pop
		reader.poll(Mifare::Classic::Tag) do |tag|
			begin
			  ws = queue.pop

				tag.auth(4, :key_a, "FFFFFFFFFFFF")
        ci = CardInfo.read(tag.read)

			  ws.send(ci.to_hash.to_json)

			  ht = present_helper(tag, queue)
			  msg = queue.pop
			  ht.exit

			  raise msg if msg.is_a? NFC::Error
			  raise "Flow error" unless msg.is_a? String

        JSON.parse(msg).each {|k,v| ci.send("#{k}=", "name" == k ? v : v.to_i)}

				tag.auth(4, :key_a, "FFFFFFFFFFFF")
			  tag.write(ci.to_binary_s)
			  tag.processed!
			rescue Exception => e
			  puts e
			ensure
			  ws.close_connection if ws.respond_to?(:close_connection)
			end
		end
	end
end

def present_helper(tag, queue)
  Thread.new do
    loop do
      unless tag.present?
        queue << NFC::Error.new("Tag not present")
        self.exit
      end
      sleep 0.05
    end
  end
end
