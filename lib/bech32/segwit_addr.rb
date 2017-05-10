module Bech32

  class SegwitAddr
    attr_accessor :hrp # human-readable part
    attr_accessor :ver # witness version
    attr_accessor :prog # witness program

    def initialize(addr = nil)
      parse_addr(addr) if addr
    end

    # Returns segwit script pubkey which generated from witness version and witness program.
    def to_script_pubkey
      v = ver == 0 ? ver : ver + 0x80
      ([v, prog.length].pack("CC") + prog.map{|p|[p].pack("C")}.join).unpack('H*').first
    end

    # Returns segwit address string which generated from hrp, witness version and witness program.
    def addr
      Bech32.encode(hrp, [ver] + convert_bits(prog, 8, 5))
    end

    private

    def parse_addr(addr)
      @hrp, data = Bech32.decode(addr)
      raise 'Invalid address.' if @hrp.nil? || (@hrp != 'bc' && @hrp != 'tb')
      @ver = data[0]
      raise 'Invalid witness version' if @ver > 16
      @prog = convert_bits(data[1..-1], 5, 8, false)
      raise 'Invalid witness program' if @prog.nil? || @prog.length < 2 || @prog.length > 40
      raise 'Invalid witness program with version 0' if @ver == 0 && (@prog.length != 20 && @prog.length != 32)
    end

    def convert_bits(data, from, to, padding=true)
      acc = 0
      bits = 0
      ret = []
      maxv = (1 << to) - 1
      max_acc = (1 << (from + to - 1)) - 1
      data.each do |v|
        return nil if v < 0 || (v >> from) != 0
        acc = ((acc << from) | v) & max_acc
        bits += from
        while bits >= to
          bits -= to
          ret << ((acc >> bits) & maxv)
        end
      end
      if padding
        ret << ((acc << (to - bits)) & maxv) unless bits == 0
      elsif bits >= from || ((acc << (to - bits)) & maxv) != 0
        return nil
      end
      ret
    end

  end
end