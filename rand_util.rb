#TODO : Impelment O(log n) sampling algorithm for RandGen by sorting all events accordint to their cummulative probabilities
#TODO : implement MarkovChain for n-th finite differences
#TODO : implement choosing distributions for unseen states by 'similarity',which if the range of the variables is numerical should be easy
#port probability.h here DONE
class Numeric
	def clamp(a,b)
		[a,self,b].sort[1]
	end
end

class RandGen
	def initialize(list=[])
		@rand = Random::new()
		@total = 0
		#probs[i][0] == item ; probs[i][1] == item count
		@probs = []

		#keep score so we only sort when we need to
		
		list.each { |i|
			add(i)
		}
		
		
		@sort_probs
	end
	
	
	public def add(item,count=1)
		found=false
		@total+=count
		
		for i in (0...@probs.size) do 
			if (@probs[i][0]==item) then 
				@probs[i][1]+=count
				found=true
				break
			end
		end

		if (not found) then
			@probs[@probs.size]=[item,count]
		end


	end
	end
	
	
	public def gen
		
		
		
		p=@rand.rand()
		i=0
		cummul_p=@probs[i][1]
		while (cummul_p/Float(@total) < p) do
			i+=1
			cummul_p+=@probs[i][1]
		end
		@probs[i][0]
	end
	
		
	public def print_probs()
		@probs.each {|i|
			puts "event #{i[0].to_s} :count #{i[1]} :prob #{i[1]/Float(@total)}\n"
		}
	end
	
	#mutate the probability distribution - mut_rate should  be between 1 and 10
	public def mutate!(n=1,mut_rate=2)
		if (@probs.length>1) then
			mut_rate=(10-mut_rate).clamp(1,10)
			
			n.times{
				from = @rand.rand(@probs.size)
				begin
					to=@rand.rand(@probs.size)
				end until (from!=to)
				mut=(@probs[from][1]/Float(mut_rate)).ceil.clamp(1,@probs[from][1])
				@probs[from][1]-=mut
				@probs[to][1]  +=mut
			}
		end
		self
	end
	
	public def mutate(n=1,mut_rate=2)
		t=self.dup
		if (@probs.length>1) then
			mut_rate=(10-mut_rate).clamp(1,10)
			
			n.times{
				from = @rand.rand(@t.size)
				begin
					to=@rand.rand(@t.size)
				end until (from!=to)
				mut=(@t[from][1]/Float(mut_rate)).ceil.clamp(1,@t[from][1])
				@t[from][1]-=mut
				@t[to][1]  +=mut
			}
		end
		
		t
	end
	

class MarkovChain
	attr_accessor :chain
	#If shuffle is true,the generation starts from a random n-length sequence.Since that way we may come across unseen states,we generate output from those states from the known probabilities.
	def initialize(n=1,shuffle=false,list=[])
		@chain = {}
		@n = n
		@state = []
		@shuffle = shuffle
		
		if (not list.empty?) then
			add(list)
		end
	end
	
	def add(list)
		cur=0
		if (not @shuffle) then
			if (@state.empty?) then
				@state=list[cur...cur+@n]
			end
		end		
		#subtract two cause we want to stop right before the last element
		while ((cur+@n)<(list.length-2)) do
			if (@chain[list[cur...(cur+@n)]]==nil) then
				@chain[list[cur...(cur+@n)]]=RandGen.new([list[(cur+@n)]])
			else
				@chain[list[cur...(cur+@n)]].add(list[(cur+@n)])
			end
			cur+=1
		end
	end
	
	def gen()
		if (@chain.empty?) then
				return
		end
		
		if (@state.empty?) then #maybe not the best way to start to generate output
			@n.times { @state[@state.length] = @chain.values[Random::rand(@chain.size)].gen() }
		end
		
		#generate a RandGen if we havent encountered this state yet.adding variability with new(@chain.keys.flatten.uniq)?
		if (@chain[@state]==nil) then
			@chain[@state]=@chain.values[Random::rand(@chain.size)].mutate!#RandGen.new(@chain.keys.flatten.uniq)
		end
		new_el=@chain[@state].gen()
		@state.shift
		@state[@state.length]=new_el
		
		new_el
	end
	
	def print_probs()
		@chain.each {|k,v|
		puts k[0].to_s
		puts v.print_probs()
		puts " "	
		}
	
	end
			
end

=begin
Abstract Class for calculating finite differences for various types of series.Inherit this class and pass it on to DerivMarkovChain
Assumes independence of differences of different orders,which is kinda stupid,but I havent yt grokked MRFs,which chould be an appropriate model for thiss
=end
class FiniteDifference
	#1st finite difference
	def self.dif(a,b)
	end
	
	#>1st nth difference.Needed in case The types for the values of the series and the derivatives differ
	def self.nthDif(a,b)
	end
	
	def self.applyDif(fx,dfx)
	end
	
	def self.applyNthDif(dfx,ddfx)
	end
end

class FiniteDifferenceMarkovChain
	attr_acessor :difGens
	#n is the max order of the finite difference that we learn,m is the order of the markov chain that we teach for each order.
	def initialize(n,differenceClass,m=10,list=nil,shuffle=false)
		@rand = Random.new()
		@n = n
		@difCl = differenceClass
		@val = nil
		#differences of the current state
		@difs = []
		@difGens = []
		
		n.times { @difGens[@difGens.size] = MarkovChain.new(m) }
	
		if (not list.nil?) then
			add(list)
		end
	end
	
	def add(list)
		if (@val.nil? and not @shuffle) then
			@val=list[0]
		else
			@val=list[rand.rand(list.size)]
		end
		prevDifs = []
		
		(0...@n).each { |i|
			nextDifs=[]
			if (i==0) then
				for y in (0...list.size-1) do
					prevDifs[prevDifs.size]=@difCl.dif(list[y],list[y+1])
				end
				@difGens[i].add(prevDifs)
			else
				for y in (0...prevDifs.size-1) do
					nextDifs[nextDifs.size]=@difCl.nthDif(prevDifs[y],prevDifs[y+1])
				end
				@difGens[i].add(nextDifs)
				prevDifs=nextDifs.dup
			end
		}
		#@difGens[0].print_probs
	end

	def gen()
		
		if (@difs.empty?) then
			(0...@n).each { |i|
				@difs[i]=@difGens[i].gen()
			}
		end
		
		@val = @difCl.applyDif(@val,@difs[0])
		
		(0...(@difs.size-1)).each { |i|
			@difs[i]=@difCl.applyNthDif(@difs[i],@difs[i+1])
		}
		@difs.pop()
		
		@val
	end
	
	
end
			
		
