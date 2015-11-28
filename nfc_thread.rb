require 'ruby-nfc'
require 'thread'
require 'json'
require './card_info'


def nfc_thread(queue)
	Thread.new do
		reader = NFC::Reader.all.pop
		loop do
      reader.poll(Mifare::Classic::Tag) do |tag|
        begin
          ws = queue.pop

          tag.auth(4, :key_a, "FFFFFFFFFFFF")
          ci = CardInfo.read(tag.read)

          ws.send(ci.to_hash.to_json)

          check_tag_presence(tag, queue)
          msg = queue.pop

          raise msg if msg.is_a? NFC::Error
          raise "Flow error" unless msg.is_a? String

          ci.from_hash(JSON.parse(msg))

          tag.auth(4, :key_a, "FFFFFFFFFFFF")
          tag.write(ci.to_binary_s)
          tag.processed!
        rescue Exception => e
          p e
        ensure
          queue.clear
          ws.close_connection if ws.respond_to?(:close_connection)
        end
      end
    end
	end
end

def check_tag_presence(tag, queue)
  Thread.new do
    loop do
      sleep 0.1
      unless tag.present?
        queue << NFC::Error.new("Tag is not present")
        self.exit
      end
    end
  end
end
