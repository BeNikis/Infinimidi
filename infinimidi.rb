require_relative "rand_util"
require "unimidi"
require "midilib"
#TODO : get the length of each individual note without needing NoteOff events , play multiple tracks / notes in tracks




			
				
		




		
	
class MidiDif < FiniteDifference
	
	def self.dif(a,b)
	{ 0 => b[0] - a[0] , 1 => b[1] - a[1] } 
	end
	
	def self.nthDif(a,b)
	{ 0 => b[0] - a[0] , 1 => b[1] - a[1] }
	end
	
	def self.applyDif(fx,dfx)
	{ 0 => (fx[0] + dfx[0]).clamp(0,127) , 1 => (fx[1] + dfx[1]).clamp(0,0.5) }
	end
	
	def self.applyNthDif(dfx,ddfx)
	{ 0 => (dfx[0] + ddfx[0]).clamp(0,127) , 1 => (dfx[1] + ddfx[1]) }
	end
end



rand = Random::new()
# Prompts the user to select a midi output
# Sends some arpeggiated chords to the output

 # C E G
duration = 0.125
#infinimidi.rb file.mid track markov_num [play]
notegen = FiniteDifferenceMarkovChain.new((ARGV[2].nil? ? 1 : ARGV[2]).to_i,MidiDif)
output = UniMIDI::Output.open(:first)
town = seq = MIDI::Sequence.new()
town.read(File.new(ARGV[0].nil? ? "ode.mid" : ARGV[0] ,"rb")) { | track, num_tracks, i |
        # Print something when each track is read.
        puts "read track #{i} of #{num_tracks}"
}
traNr = (ARGV[1].nil? ? 1 : ARGV[1]).to_i


if (not ARGV[3].nil?) then
	town.tracks[traNr].each { |ev|
		if (ev.is_a? MIDI::NoteEvent) then
			
			output.puts(*ev.data_as_bytes[0..1]<<127)
			sleep(town.pulses_to_seconds(ev.delta_time))
		elsif (ev.is_a? MIDI::ProgramChange) 
			output.puts(0xC0,ev.data_as_bytes[1])
		end
	}
end


notegen.add( (town.tracks[traNr].select { |ev| ev.is_a? MIDI::NoteEvent }).map { |ev| {0 => ev.data_as_bytes[1] , 1 => town.pulses_to_seconds(ev.delta_time).clamp(0,1)}} )
note=notegen.gen()





puts "Analysis/testing succeded.Playing that funky music."


while true do
	output.puts(0x90, note[0], 127) # note on
    sleep(note[1]) # wait
    output.puts(0x80, note[0], 127) # note off
	
	note=notegen.gen()
	
	duration=0.25#(duration*((rand.rand(2)==1) ? 2 : 0.5)).clamp(0.0625,0.4)
end

