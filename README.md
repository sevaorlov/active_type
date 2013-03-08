# ActiveType

This gem adds PostgreSQL user defined types support for Active Record (Ruby on Rails).

## Installation

Add this line to your application's Gemfile:

    gem 'active_type'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_type

## Usage

1) Create a new class in PostgreSQL: 
    
    CREATE TYPE your_type AS (property1 varchar, property2 datetime, property3 text);

2) Specify new column in your model table:
    
    add_column :model_table_name, :your_type_name, :your_type

3) Specify in your model 

    serialize :your_type_name, YourTypeClass

in your model.

Gem also supports arays and one level nested types.

Limitations:
1) Doesnt support commas in arrays
2) Doesnt support multiple level nested types
3) Maybe doesnt support bytea type

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
