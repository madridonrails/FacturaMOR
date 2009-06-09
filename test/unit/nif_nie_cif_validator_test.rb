require File.dirname(__FILE__) + '/../test_helper'

class NifNieCifValidatorTest < Test::Unit::TestCase
  
  def nif?(code)
    FacturagemUtils.nif?(code)
  end

  def nie?(code)
    FacturagemUtils.nie?(code)
  end

  def cif?(code)
    FacturagemUtils.cif?(code)
  end
  
  def check_nif(nif)
    assert nif?(nif)
    assert !nif?("foo#{nif}")
    assert !nif?("#{nif}bar")

    nif = nif.dup
    letter = nif.last
    ('A'..'Z').to_a.each do |c|
      next if c == letter
      nif.sub!(/.$/, c)
      assert !nif?(nif)
    end
  end
  
  def test_nifs
    check_nif('35110704P') # fxn
    check_nif('43419016F') # andres
    check_nif('25465828K') # supercoco
    check_nif('78748494J') # leptom
    check_nif("09408808Z")
    check_nif("27346906K")
    check_nif("28727310B")
    check_nif("25578001T")
    check_nif("52692902V")
    check_nif("25047502L")
    check_nif("25591920G")
    check_nif("28752401D")
    check_nif("25570999J")
    check_nif("30835823E")
    check_nif("09688701C")
    check_nif("24228322F")
    check_nif("25589165D")
    check_nif("45065603R")
    check_nif("26489047Q")
    check_nif("31841249A")
    check_nif("31261424P")
    check_nif("25562456A")
    check_nif("26481713L")
    check_nif("33365246C")
    check_nif("24205965Y")
    check_nif("25581627S")
    check_nif("74669890E")
    check_nif("44575299B")
    check_nif("26022693X")
    check_nif("52545006B")
    check_nif("28728774A")
    check_nif("30810866C")
    check_nif("28473035R")
    check_nif("44290788X")
    check_nif("52583319Y")
    check_nif("45274265F")
    check_nif("27529573E")
    check_nif("25569069S")
    check_nif("44252933J")
    check_nif("26027923L")
    check_nif("05352324V")
    check_nif("33366151M")
    check_nif("26029193R")
    check_nif("33384132T")
    check_nif("25561522N")
    check_nif("25578580G")
    check_nif("02537342M")
    check_nif("25066778K")
    check_nif("23800203X")
    check_nif("24260261E")
    check_nif("74901128H")
    check_nif("26214539J")
    check_nif("74087755V")
    check_nif("32034276Z")
    check_nif("44610933H")
    
    # a couple with less than 8 digits
    check_nif("01159958E")
    check_nif("1159958E")
    check_nif("02858695W")
    check_nif("2858695W")
    check_nif("00798757J")
    check_nif("798757J")
  end
  
  def check_nie(nie)
    assert nie?(nie)
    assert !nie?("foo#{nie}")
    assert !nie?("#{nie}bar")

    nie = nie.dup
    letter = nie.last
    ('A'..'Z').to_a.each do |c|
      next if c == letter
      nie.sub!(/.$/, c)
      assert !nie?(nie)
    end
  end

  def test_nies
    check_nie("X3425347A")
    check_nie("X3604553Q")
    check_nie("X4326156V")
    check_nie("X4528673L")
    check_nie("X5147545F")
    check_nie("X5243001J")
    check_nie("X5291093N")
    check_nie("X7458807E")
    check_nie("X7850493H")
    check_nie("X03402718Y")
    check_nie("X07934061G")
    check_nie("X08250720E")
  end

  def check_cif(cif)
    assert cif?(cif)
    assert !cif?("foo#{cif}")
    assert !cif?("#{cif}bar")

    cif = cif.dup
    control = cif.last
    ['A'..'Z', '0'..'9'].map(&:to_a).flatten.each do |c|
      next if c == control
      # careful, for some CIFs there's a number/letter that would still be valid
      next if !%w(A B E H K P Q S).include?(cif.at(0)) && c = "JABCDEFGHI".at(control.to_i)
      cif.sub!(/.$/, c)
      assert !cif?(cif)
    end
  end
  
  def test_cifs
    check_cif("A08065021") # Enher
    check_cif("A08115032") # Caprabo
    check_cif("A08372351") # Editorial Vicens-Vives
    check_cif("A28000727") # Banco Popular Español
    check_cif("A28017895") # El Corte Ingles
    check_cif("A58818501") # Everybody in online examples uses this one
    check_cif("A61994836") # iSOCO
    check_cif("A80500200") # FNAC
    check_cif("A84742535") # Centros Educativos Madrileños
    check_cif("B39495460") # Editorial Cantabria Interactiva
    check_cif("B60521424") # J. Noria S.L.
    check_cif("B84741164") # ASPgems
    check_cif("B95307641") # Gabinete Educativo 2000
    check_cif("E13375076") # UNACHINAENMIZAPATO*ADVERSATIVE
    check_cif("E78301769") # Comunidad de Propietarios de la calle Moratín, número 30
    check_cif("F30083505") # Sociedad Cooperativa Hortofrutícola Ciezana
    check_cif("G22202774") # InfoPirineo
    check_cif("G92654250") # Europa Mortgages
    check_cif("Q2817026D") # Comision del Mercado de las Telecomunicaciones
    check_cif("Q2830103D") # Ministerio de Justicia
  end
end