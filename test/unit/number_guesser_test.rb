require File.dirname(__FILE__) + '/../test_helper'

class NumberGuesserTest < Test::Unit::TestCase
  
  def guess(*numbers)
    Invoice.send(:guess_next_number_aux, numbers)
  end
  
  def setup
    @current_year = Date.today.year.to_s
    @separators = %w(- / : _ V)
  end

  def test_first_invoice
    assert_equal "#{Date.today.year}_0001", guess
  end
  
  def test_no_ambiguity
    0.upto(3) do |i|
      @separators.each do |sep|
        year = @current_year[i..3] # "2007", "007", "07", "7" depending on i
        assert_equal "4",   guess("3")
        assert_equal "100", guess("99")

        assert_equal "#{year}#{sep}58", guess("#{year}#{sep}57")
        assert_equal "58#{sep}#{year}", guess("57#{sep}#{year}")
      
        assert_equal "F4#{sep}#{year}",   guess("F3#{sep}#{year}")
        assert_equal "F100#{sep}#{year}", guess("F99#{sep}#{year}")        

        assert_equal "#{year}#{sep}F4",   guess("#{year}#{sep}F3")
        assert_equal "#{year}#{sep}F100", guess("#{year}#{sep}F99")
      
        assert_equal "#{year}#{sep}0002",  guess("#{year}#{sep}0001")
        assert_equal "#{year}#{sep}0004",  guess("#{year}#{sep}0003")
        assert_equal "#{year}#{sep}0100",  guess("#{year}#{sep}0099")
        assert_equal "#{year}#{sep}10000", guess("#{year}#{sep}9999")
      
        assert_equal "0004#{sep}#{year}",  guess("0003#{sep}#{year}")
        assert_equal "0100#{sep}#{year}",  guess("0099#{sep}#{year}")
        assert_equal "10000#{sep}#{year}", guess("9999#{sep}#{year}")
      
        assert_equal "#{year}#{sep}4",   guess("#{year}#{sep}3")
        assert_equal "#{year}#{sep}100", guess("#{year}#{sep}99")

        assert_equal "4#{sep}#{year}",   guess("3#{sep}#{year}")
        assert_equal "100#{sep}#{year}", guess("99#{sep}#{year}")
        
        assert_equal "proforma04", guess("proforma03")
        assert_equal "proforma10", guess("proforma09")
        assert_equal "proforma100", guess("proforma99")
      
        assert_equal "Serv#{sep}#{year}#{sep}0004",  guess("Serv#{sep}#{year}#{sep}0003")
        assert_equal "Serv#{sep}#{year}#{sep}0100",  guess("Serv#{sep}#{year}#{sep}0099")
        assert_equal "Serv#{sep}#{year}#{sep}10000", guess("Serv#{sep}#{year}#{sep}9999")

        assert_equal "Serv#{sep}0004#{sep}#{year}",  guess("Serv#{sep}0003#{sep}#{year}")
        assert_equal "Serv#{sep}0100#{sep}#{year}",  guess("Serv#{sep}0099#{sep}#{year}")
        assert_equal "Serv#{sep}10000#{sep}#{year}", guess("Serv#{sep}9999#{sep}#{year}")
        
        assert_equal "GG#{sep}#{year}#{sep}0004", guess("GG#{sep}#{year}#{sep}0003")
        assert_equal "GG#{sep}#{year}#{sep}0100", guess("GG#{sep}#{year}#{sep}0099")
        assert_equal "GG#{sep}#{year}#{sep}10000", guess("GG#{sep}#{year}#{sep}9999")        
      end
    end
  end
  
  def test_ambiguity
    0.upto(3) do |i|
      @separators.each do |sep|
        year = @current_year[i..3] # "2007", "007", "07", "7" depending on i
        
        assert_equal "F08#{sep}#{year}",   guess("F07#{sep}#{year}", "F06#{sep}#{year}")
        assert_equal "F2008#{sep}#{year}", guess("F2007#{sep}#{year}", "F2006#{sep}#{year}")

        assert_equal "#{year}#{sep}F08",   guess("#{year}#{sep}F07", "#{year}#{sep}F06")
        assert_equal "#{year}#{sep}F2008", guess("#{year}#{sep}F2007", "#{year}#{sep}F2006")

        assert_equal "#{year}#{sep}0008",  guess("#{year}#{sep}0007", "#{year}#{sep}0006")
        assert_equal "#{year}#{sep}2008",  guess("#{year}#{sep}2007", "#{year}#{sep}2006")
        
        assert_equal "0008#{sep}#{year}",  guess("0007#{sep}#{year}", "0006#{sep}#{year}")
        assert_equal "2008#{sep}#{year}",  guess("2007#{sep}#{year}", "2006#{sep}#{year}")
      
        assert_equal "#{year}#{sep}8",    guess("#{year}#{sep}7", "#{year}#{sep}6")
        assert_equal "#{year}#{sep}2008", guess("#{year}#{sep}2007", "#{year}#{sep}2006")

        assert_equal "8#{sep}#{year}",    guess("7#{sep}#{year}", "6#{sep}#{year}")
        assert_equal "2008#{sep}#{year}", guess("2007#{sep}#{year}", "2006#{sep}#{year}")
        
        assert_equal "proforma08", guess("proforma07", "proforma06")
        assert_equal "proforma2008", guess("proforma2007", "proforma2006")
              
        assert_equal "Serv#{sep}#{year}#{sep}0008",  guess("Serv#{sep}#{year}#{sep}0007", "Serv#{sep}#{year}#{sep}0006")
        assert_equal "Serv#{sep}#{year}#{sep}2008",  guess("Serv#{sep}#{year}#{sep}2007", "Serv#{sep}#{year}#{sep}2006")

        assert_equal "Serv#{sep}0008#{sep}#{year}",  guess("Serv#{sep}0007#{sep}#{year}", "Serv#{sep}0006#{sep}#{year}")
        assert_equal "Serv#{sep}2008#{sep}#{year}",  guess("Serv#{sep}2007#{sep}#{year}", "Serv#{sep}2006#{sep}#{year}")

        assert_equal "GG#{sep}#{year}#{sep}0008", guess("GG#{sep}#{year}#{sep}0007", "GG#{sep}#{year}#{sep}0006")
        assert_equal "GG#{sep}#{year}#{sep}2008", guess("GG#{sep}#{year}#{sep}2007", "GG#{sep}#{year}#{sep}2006")        
      end
    end
  end
end
