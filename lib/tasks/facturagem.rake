require 'yaml'
require 'erb'

namespace :facturagem do

  desc "creates the schema of the database"
  task :create_schema => :environment do
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    sql_for_encoding = config['encoding'] ? "character set #{config['encoding']}" : ''
    IO.popen("mysql -u root -p", 'w') do |pipe|
      pipe.write <<-SQL
        drop database if exists #{config['database']};
        create database #{config['database']} #{sql_for_encoding};
        grant all on #{config['database']}.* to '#{config['user']}'@'localhost' identified by '#{config['password']}';
      SQL
    end
  end
  
  desc "creates the schema and runs migrations"
  task :create_database => ['create_schema', 'db:migrate'] do
  end
  
  desc "create countries"
  task :create_countries => :environment do
    puts "loading countries"
    [
      "Afganistán",
      "Islas Åland",
      "Albania",
      "Alemania",
      "Andorra",
      "Angola",
      "Anguilla",
      "Antártida",
      "Antigua y Barbuda",
      "Antillas Holandesas",
      "Arabia Saudí",
      "Argelia",
      "Argentina",
      "Armenia",
      "Aruba",
      "Australia",
      "Austria",
      "Azerbaiyán",
      "Bahamas",
      "Bahréin",
      "Bangladesh",
      "Barbados",
      "Bielorrusia",
      "Bélgica",
      "Belice",
      "Benin",
      "Bermudas",
      "Bhután",
      "Bolivia",
      "Bosnia y Herzegovina",
      "Botsuana",
      "Isla Bouvet",
      "Brasil",
      "Brunéi",
      "Bulgaria",
      "Burkina Faso",
      "Burundi",
      "Cabo Verde",
      "Islas Caimán",
      "Camboya",
      "Camerún",
      "Canadá",
      "República Centroafricana",
      "Chad",
      "República Checa",
      "Chile",
      "China",
      "Chipre",
      "Islas Cocos",
      "Colombia",
      "Comoras",
      "República del Congo",
      "República Democrática del Congo",
      "Islas Cook",
      "Corea del Norte",
      "Corea del Sur",
      "Costa de Marfil",
      "Costa Rica",
      "Croacia",
      "Cuba",
      "Dinamarca",
      "Dominica",
      "República Dominicana",
      "Ecuador",
      "Egipto",
      "El Salvador",
      "Emiratos Árabes Unidos",
      "Eritrea",
      "Eslovaquia",
      "Eslovenia",
      "España",
      "Estados Unidos",
      "Islas ultramarinas de Estados Unidos",
      "Estonia",
      "Etiopía",
      "Islas Feroe",
      "Filipinas",
      "Finlandia",
      "Fiyi",
      "Francia",
      "Gabón",
      "Gambia",
      "Georgia",
      "Islas Georgias del Sur y Sandwich del Sur",
      "Ghana",
      "Gibraltar",
      "Granada",
      "Grecia",
      "Groenlandia",
      "Guadalupe",
      "Guam",
      "Guatemala",
      "Guayana Francesa",
      "Guernesey",
      "Guinea",
      "Guinea Ecuatorial",
      "Guinea-Bissau",
      "Guyana",
      "Haití",
      "Islas Heard y McDonald",
      "Honduras",
      "Hong Kong",
      "Hungría",
      "India",
      "Indonesia",
      "Irán",
      "Iraq",
      "Irlanda",
      "Islandia",
      "Israel",
      "Italia",
      "Jamaica",
      "Japón",
      "Jersey",
      "Jordania",
      "Kazajistán",
      "Kenia",
      "Kirguistán",
      "Kiribati",
      "Kuwait",
      "Laos",
      "Lesotho",
      "Letonia",
      "Líbano",
      "Liberia",
      "Libia",
      "Liechtenstein",
      "Lituania",
      "Luxemburgo",
      "Macao",
      "ARY Macedonia",
      "Madagascar",
      "Malasia",
      "Malawi",
      "Maldivas",
      "Malí",
      "Malta",
      "Islas Malvinas",
      "Isla de Man",
      "Islas Marianas del Norte",
      "Marruecos",
      "Islas Marshall",
      "Martinica",
      "Mauricio",
      "Mauritania",
      "Mayotte",
      "México",
      "Micronesia",
      "Moldavia",
      "Mónaco",
      "Mongolia",
      "Montserrat",
      "Mozambique",
      "Myanmar",
      "Namibia",
      "Nauru",
      "Isla de Navidad",
      "Nepal",
      "Nicaragua",
      "Níger",
      "Nigeria",
      "Niue",
      "Isla Norfolk",
      "Noruega",
      "Nueva Caledonia",
      "Nueva Zelanda",
      "Omán",
      "Países Bajos",
      "Pakistán",
      "Palau",
      "Palestina",
      "Panamá",
      "Papúa Nueva Guinea",
      "Paraguay",
      "Perú",
      "Islas Pitcairn",
      "Polinesia Francesa",
      "Polonia",
      "Portugal",
      "Puerto Rico",
      "Qatar",
      "Reino Unido",
      "Reunión",
      "Ruanda",
      "Rumania",
      "Rusia",
      "Sahara Occidental",
      "Islas Salomón",
      "Samoa",
      "Samoa Americana",
      "San Cristóbal y Nevis",
      "San Marino",
      "San Pedro y Miquelón",
      "San Vicente y las Granadinas",
      "Santa Helena",
      "Santa Lucía",
      "Santo Tomé y Príncipe",
      "Senegal",
      "Serbia y Montenegro",
      "Seychelles",
      "Sierra Leona",
      "Singapur",
      "Siria",
      "Somalia",
      "Sri Lanka",
      "Suazilandia",
      "Sudáfrica",
      "Sudán",
      "Suecia",
      "Suiza",
      "Surinam",
      "Svalbard y Jan Mayen",
      "Tailandia",
      "Taiwán",
      "Tanzania",
      "Tayikistán",
      "Territorio Británico del Océano Índico",
      "Territorios Australes Franceses",
      "Timor Oriental",
      "Togo",
      "Tokelau",
      "Tonga",
      "Trinidad y Tobago",
      "Túnez",
      "Islas Turcas y Caicos",
      "Turkmenistán",
      "Turquía",
      "Tuvalu",
      "Ucrania",
      "Uganda",
      "Uruguay",
      "Uzbekistán",
      "Vanuatu",
      "Ciudad del Vaticano",
      "Venezuela",
      "Vietnam",
      "Islas Vírgenes Británicas",
      "Islas Vírgenes de los Estados Unidos",
      "Wallis y Futuna",
      "Yemen",
      "Yibuti",
      "Zambia",
      "Zimbabue"
    ].each do |name|
      Country.create(:name => name)
    end
  end

  desc 'to be described'
  task :init => :create_countries do
  end
  
  desc 'creates a dummy plan, enterprise, owner to bootstrap development, tables will be cleared'
  task :create_dummy_models => :environment do
    spain_id = Country.find_by_name_for_sorting('espana').id
    Account.destroy_all
    
    dummy_account = Account.create(
      :name        => 'Madrid on Rails, S.L.',
      :short_name  => 'mor',
      :is_active   => true,
      :is_blocked  => false
    )
    dummy_account.create_fiscal_data(
      :name        => 'Madrid on Rails, S.L.',
      :cif         => 'B-84741164',
      :iva_percent => 16
    ).create_address(
      :street1     => 'Castellana, 5',
      :postal_code => '28002',
      :city        => 'Madrid',
      :province    => 'Madrid',
      :country_id  => spain_id
    )    
    puts "created dummy account with fiscal data"    
    
    u = dummy_account.users.create(
      :first_name            => 'Manuel',
      :last_name             => 'Castañeda',
      :email                 => 'admin@example.com',
      :email_confirmation    => 'admin@example.com',
      :password              => 'admin',
      :password_confirmation => 'admin',
      :activated_at          => Time.now
    )
    dummy_account.owner = u
    dummy_account.save!
    
    dummy_account.customers.create(
      :name => 'Fernández Hermanos, S.L.',
      :cif  => 'B-62522289',
      :discount_percent => 2
    ).create_address(
      :street1     => 'Arizala 13, bajos',
      :city        => 'Deixebre',
      :province    => 'A Coruña',
      :postal_code => '15706',
      :country_id  => spain_id
    )

    dummy_account.customers.create(
      :name => 'Laboratorios Laredo, S.A.',
      :cif  => 'A-84095256',
      :discount_percent => 3
    ).create_address(
      :street1 => 'Vallespir 37',
      :city => 'Villanueva de Gómez',
      :province => 'Ávila',
      :postal_code => '05005',
      :country_id => spain_id
    )
    
    dummy_account.customers.create(
      :name => 'Reyab Químicos, S.L.',
      :cif  => 'A-60912508',
      :discount_percent => 4
    ).create_address(
      :street1 => 'Enric Granados 126',
      :city => 'Barcelona',
      :province => 'Barcelona',
      :postal_code => '08045',
      :country_id => spain_id
    )

    dummy_account.customers.create(
      :name => 'GMB S. Electrónicos, S.L.',
      :cif  => 'A-29073806',
      :discount_percent => 7.8
    ).create_address(
      :street1     => 'Llobregat, 63, bajos',
      :city        => "L'Hospitalet de Llobregat",
      :province    => 'Barcelona',
      :postal_code => '08904',
      :country_id  => spain_id
    )
    
    dummy_account.customers.create(
      :name => 'Agip España',
      :cif  => 'A-28188464'
    ).create_address(
      :street1     => 'Anabel Segura, 16',
      :street2     => 'Edificio Vega Norte I',
      :city        => 'Alcobendas',
      :province    => 'Madrid',
      :postal_code => '28108',
      :country_id  => spain_id
    )
    
    dummy_account.customers.create(
      :name => 'Salvador Gomà i Associats',
      :cif  => '38387101D',
      :discount_percent => 10
    ).create_address(
      :street1     => 'Provença, 214, 6è 2a',
      :city        => 'Barcelona',
      :province    => 'Barcelona',
      :postal_code => '08036',
      :country_id  => spain_id
    )

    dummy_account.customers.create(
      :name => 'Grandes Almacenes Fnac España, S.A.',
      :cif  => 'A-80/500200',
      :discount_percent => 12.57
    ).create_address(
      :street1     => 'Paseo de la Finca, 1',
      :street2     => 'Bloque 11, 2ª Planta',
      :city        => 'Pozuelo de Alarcón',
      :province    => 'Madrid',
      :postal_code => '28223',
      :country_id  => spain_id
    )
    puts "created #{dummy_account.customers.size} dummy customers for dummy account"
    
    invoice = Invoice.new(
      :number => "F1-07",
      :date => Date.civil(2007, 3, 4),
      :iva_percent => dummy_account.fiscal_data.iva_percent,
      :discount_percent => dummy_account.customers.first.discount_percent
    )
    invoice.account = dummy_account
    invoice.customer = dummy_account.customers.first
    invoice.save!
    invoice.lines.create(
      :amount => 8.0,
      :description => 'Reparación de la caldera de la nave central',
      :price => 50.0
    )
    invoice.lines.create(
      :amount => 1,
      :description => 'Desplazamiento',
      :price => 25
    )
    invoice.lines.create(
      :amount => 1,
      :description => 'Materiales',
      :price => 37.56
    )
    invoice.save!

    invoice = Invoice.new(
      :number => "F2-07",
      :date => Date.civil(2007, 3, 7),
      :iva_percent => dummy_account.fiscal_data.iva_percent,
      :discount_percent => dummy_account.customers[3].discount_percent
    )
    invoice.account = dummy_account
    invoice.customer = dummy_account.customers[3]
    invoice.save!
    invoice.lines.create(
      :amount => 12.0,
      :description => 'Mantenimiento de turbinas de calefacción',
      :price => 50.0
    )
    invoice.lines.create(
      :amount => 1,
      :description => 'Desplazamiento',
      :price => 25
    )
    invoice.lines.create(
      :amount => 1,
      :description => 'Materiales',
      :price => 154.58
    )
    invoice.save!

    invoice = Invoice.new(
      :number => "F3-07",
      :date => Date.civil(2007, 3, 9),
      :iva_percent => dummy_account.fiscal_data.iva_percent,
      :discount_percent => dummy_account.customers[4].discount_percent
    )
    invoice.account = dummy_account
    invoice.customer = dummy_account.customers[4]
    invoice.save!
    invoice.lines.create(
      :amount => 23.0,
      :description => 'Renovación tuberías de refrigeración',
      :price => 50.0
    )
    invoice.lines.create(
      :amount => 1,
      :description => 'Desplazamiento',
      :price => 25
    )
    invoice.lines.create(
      :amount => 1,
      :description => 'Materiales',
      :price => 543.32
    )
    invoice.save!
    
    puts "created #{dummy_account.invoices.size} dummy invoices"
  end
  
  desc 'DESTROYs the current database, if any, and creates a new one with dummy models'
  task :init_for_development => [:create_database, :init, :create_dummy_models] do
  end
end
