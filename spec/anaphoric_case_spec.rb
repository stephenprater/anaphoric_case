require 'spec_helper'

require 'anaphoric_case'
require 'timeout'

describe "it is an anaphoric case" do
  
  before :all do
    class Harness
      def initialize 
        @array = [1,2,3,4,5]
        @hash = { :bacon => "cheese", :pie => "sky", :snoopy => "pizza" }
        @string = "That is quite a mustache you've got there, sheriff."
        @snitch = 0 
      end

      def count
        @array
      end

      def flavors thing
        @hash[thing] 
      end

      def compliment
        @string
      end

      def snitch
        @snitch
      end

      def narc
        @snitch += 1
        if @string == "I committed regicide"
          true
        else
          false
        end
      end

      def cover_evidence
        @string = "I committed regicide"
        false
      end
    end
  end

  before :each do
    @test = Harness.new
  end

  profile :all do

    it "provides a simple aif method" do
      res = nil
      aif(5 + 4) { |it| res = it }
      res.should == 9

      res = nil
      res = aif(5 + 4) { 'okay!' }
      res.should == 'okay!'

      res = aif(5 < 4) { 'monkey' }
      res.should == false
    end

    it "should return the first object which is truthy" do
      res = switch do
        on 1
        on false
        on nil
      end
      res.should == 1

      res = switch do
        on false
        on 2
        on nil
      end

      res.should == 2

      res = switch do
        on false
        on nil
        on :bob
      end
      res.should == :bob

      res = switch do
        on false
        on [1,2,3,4,5]
      end
      res.should == [1,2,3,4,5]

    end

    it "is lazy" do
      res = switch do
        on @test.narc
        on @test.cover_evidence
        on @test.narc
        on @test.compliment
      end
      res.should == true
      @test.snitch.should == 2
    end

    it "can execute anaphoric blocks using on" do
      res = switch do
        on(false) { |it| it.blah_blah } #this would raise an error if it was ever called 
        on(1) { |it| it + 1 }
      end
      res.should == 2
    end

    it "can have an else clause by way of on with no parameters" do
      res = switch do
        on false
        on nil
        on { 5 } 
      end
      res.should == 5
      
      res = switch do
        on 1
        on { 1 } 
      end
      res.should == 1
    end

    it "on blocks which return falsey cause evaulation to continue" do
      res = switch do
        on { nil }
        on { :turtle }
      end
      res.should == :turtle
    end

    it "can execute within an object" do
      test_test = proc do
        switch do
          on(count.length > 5)   { count }
          on(count.length < 5)   { count }
          on(count.length == 5)  { :five }
        end
      end
      
      @test.instance_eval(&test_test).should == :five
      @test.count.slice!(0,3)
      @test.instance_eval(&test_test).should == [4,5]
      @test.count.concat [1,1,1,1]
      @test.instance_eval(&test_test).should == [4,5,1,1,1,1] 
    end

    it "can look in an object if it's not within it" do
      res = switch do
        on(@test.flavors :lime)
        on(@test.flavors :snoopy)
        on(@test.flavors :mushrooms)
      end
      res.should == "pizza"
    end

    it "can't call on from outside of switch block" do
      lambda { on }.should raise_error NameError

      # ensure the on method is defined the next time
      # we call it
      flag = false 
      t1 = Thread.new do
        switch do
          on false
          flag = true 
          sleep 0.1
          on true
        end
        flag = false
      end
      
      Timeout.timeout(1) { loop until flag == true }

      # should transform the uncaught :throw error into a NameError 
      (self.respond_to? :on).should be true #it's defined in the thread
      lambda { on }.should raise_error NameError, "on without associated switch"

      loop until flag == false
      (self.respond_to? :on).should be false
      lambda { on }.should raise_error NameError
    end

    it "can raise past the (internal) throw" do
      lambda do 
        switch do
          on { |a,b,c| raise ArgumentError } 
        end
      end.should raise_error ArgumentError 
    end

    it "can nest safely" do
      res = switch do
        on(@test.compliment =~ /mustache/) do |it|
          switch do
            on(@test.compliment =~ /baron/) { "The Barons Mustache"}
            on(@test.compliment =~ /sheriff/) { "The Sheriff's Mustache" }
          end
        end
        on(@test.count == 5)
      end
      res.should == "The Sheriff's Mustache"

      res = switch do
        on do |it|
          switch do
            on { nil }
          end
        end
        on { 5 }
      end
      res.should == 5
    end

    it "can be called with explicit receiver" do 
      # this makes it act a little bit like "tap"
      res = @test.switch do
        on (flavors :lime) { |it| it.blah } #would raise
        on (flavors :snoopy) 
        on { raise 'terribly awry'}
      end

      res.should == "pizza"
    end

    it "can act like a regular case statement if called with a parameter" do
      test = lambda do |test_obj|
        res = switch test_obj do
          on(/baron/)   { |it| "'#{it.chomp('.')},' said the queen."}
          on(/sheriff/) { |it| "'#{it.chomp('.')},' I said."}
          on
        end
      end
       
      test.call("That's a nice mustache sheriff.").should == "'That's a nice mustache sheriff,' I said."
      test.call("That's a nice mustache baron.").should == "'That's a nice mustache baron,' said the queen."
      test.call("I hate mustache's").should == "I hate mustache's"
    end

    it "can act like a regular case statement nested" do
      remember = @test.compliment.dup
      res = switch @test.compliment do
        on /sheriff/ do |it|
          # its is @test.compliment
          switch it do
            #it is STILL @test.compliment
            on(/mustache/) { |thing| false } 
            #return false to fall through
          end
        end
        # here it should STILL be @test.compliment
        # which means this should NOT match
        on(/baron/) { |it| it.blah }
        # but this should.
        on(/sheriff/) { |it| it + "okay" } 
      end
      res.should == remember + "okay"
    end

    it "can be called both with and without a parameter" do
      res = switch do
        # there is no default __it__
        on @test.compliment =~ /sheriff/ do |it| 
          # it here is "43" the place where sheriff occures
          switch it do |ot|
            on(ot > 43)  { raise 'ohnoes' }
            on(ot < 43)  { raise 'ohnoes again'} 
            # this will signal completion
            on(ot == 43) { 'okay!' }
          end
        end
        # so this will not run 
        on(@test.compliment =~ /baron/) { |it| it.blah }
      end

      res.should == 'okay!'
      
      res = switch @test.compliment do
        # this will match
        on /mustache/ do |it|
          switch do
            # this should not match, but it's truthy
            on /poor/
          end
        end
      end
      
      #so the result of the entire block is the last truthy thing
      res.should == /poor/

      res = switch @test.compliment do
        on /mustache/ do |it|
          # this will CLOSE around it.
          switch do
            on(it =~ /sheriff/) { 'yes it is' }
            on true
          end
        end
        on(/baron/) { true }
      end
      res.should == 'yes it is'

      
      # can switch eval contexts each time
      
      res = switch "this" do
        on /this/ do
          switch "that" do
            on /that/ do
              switch "thing" do
                on /thing/ do
                  "foogle bear" 
                end
              end
            end
          end
        end
      end

      res.should == "foogle bear"
    end

    it "nests in threads" do
      res1, res2 = nil,nil

      t1 = Thread.new do
        res1 = switch "this" do
          on /this/ do
            switch "that" do 
              on(/that/) { "that" }
            end
          end
        end
      end

      t2 = Thread.new do
        res2 = switch "weasel" do
          on /weasel/ do
            switch "monkey" do
              on(/monkey/) { "monkey" }
            end
          end
        end
      end

      Timeout.timeout 1 do
        loop do
          t = [t1.status, t2.status]
          t.delete(false)
          break if t.empty?
        end
      end

      res1.should == "that"
      res2.should == "monkey"
    end

    it "reusing blocks with params works across threads" do
      thing = proc do
        on(/Pestilence/) { |it| sleep 0.1; "#{it} made you cough." } #yep, mess it up
        on(/Death/) { |it| "#{it} killed you." }
        on(/Famine/) { |it| "#{it} made you hungry."}
        on(/War/) { |it| "#{it} was loud." }
      end
    
      res1 = switch "War in Iraq", &thing
      res1.should == "War in Iraq was loud."

      res2, res3,res4 = nil, nil, nil

      t1 = Thread.new do
        res2 = switch "Famine in Ireland", &thing
      end

      t2 = Thread.new do
        res3 = switch "Death at a Funeral", &thing
      end

      t3 = Thread.new do
        res4 = switch "Pestilence at the presschool", &thing
      end

      Timeout.timeout 1 do
        loop do
          t = [t1.status, t2.status, t3.status]
          t.delete(false)
          break if t.empty?
        end
      end
      
      res2.should == "Famine in Ireland made you hungry."
      res3.should == "Death at a Funeral killed you."
      res4.should == "Pestilence at the presschool made you cough."
    end

    it "threads?" do
      res1, res2, res3 = nil, nil, nil
        
      t1 = Thread.new do
        res1 = switch do
          on(@test.flavors :lime)
          on(@test.flavors :snoopy)
          on(@test.flavors :bacon)
        end
      end

      t2 = Thread.new do
        res2 = switch do
          on(@test.count.length == 6)
          on(@test.count.length == 5) { @test.count }
        end
      end

      # this is designed to make sure it running after the first two
      # finish.  if switch isn't thread safe, the last
      # call to on will raise NoMethodError
      t3 = Thread.new do
        res3 = switch do
          on false
          on nil
          sleep 0.1 
          on true
        end
      end
      
      Timeout.timeout 1 do
        loop do
          t = [t1.status, t2.status, t3.status]
          t.delete(false)
          break if t.empty?
        end
      end

      res1.should == "pizza"
      res2.should == [1,2,3,4,5] 
      res3.should == true
    end
  end
end
        
        
      
    

    
