# Onsi

Used to generate API responses from a Rails App.

***

[![CircleCI](https://circleci.com/gh/skylarsch/onsi.svg?style=svg)](https://circleci.com/gh/skylarsch/onsi)

[![Maintainability](https://api.codeclimate.com/v1/badges/c3ee44371f7565f2709c/maintainability)](https://codeclimate.com/github/skylarsch/onsi/maintainability)

[![Test Coverage](https://api.codeclimate.com/v1/badges/c3ee44371f7565f2709c/test_coverage)](https://codeclimate.com/github/skylarsch/onsi/test_coverage)

### Install

1. Add `gem 'onsi'` to your Gemfile

2. `bundle install`

## Getting Setup

### Controllers

`Onsi::Controller` handles rendering resources for you.

```ruby
class PeopleController < ApplicationController
  include Onsi::Controller

  # Optional. By default Onsi will render `:v1`
  render_version :v2

  def show
    @person = Person.find(params[:id])
    # You can pass an Object, Enumerable, or Onsi::Resource
    # Whatever you pass, the object or each element in the collection *MUST*
    # include `Onsi::Model`
    render_resource @person
  end
end
```

### Models

Used to define your API resources. Calling the class method `api_render` will
allow you to begin setting up a version of your API. You're able to define as
many API versions as you would like. The default rendered if nothing is
specified in the `render_resource` method is `:v1`.

```ruby
class Person < ApplicationRecord
  include Onsi::Model

  api_render(:v1) do
    # Passing the name of the attribute only will call that name as a method on
    # the instance of the method.
    attribute(:first_name)
    attribute(:last_name)
    # You can give attribute a block and it will be called on the object
    # instance. This lets you rename or compute attributes
    attribute(:full_name) { "#{first_name} #{last_name}" }

    # Relationship requires a minimum of 2 parameters. The first is the name
    # of the relationship in the rendered JSON. The second is the type.
    # When fetching the value, Onsi will add `_id` and call that method on the
    # object instance. e.g. `team_id` in this case.
    relationship(:team, :team)

    # Relationships can take a block that will be called on the object instance
    # and the return value will be used as the ID
    relationship(:primary_email, :email) { emails.where(primary: true).first.id }
  end
end
```

### Params

`Onsi::Params` can be used to flatten params that come into the API.

Calling `.parse` will give you an instance of `Onsi::Params` with whitelisted
attributes & relationships. The first argument is the params from the controller.
The second is an array of attributes and the third is an array of relationships.

Calling `#flatten` will merge the attributes & relationships.

```json
{
  "data": {
    "type": "person",
    "attributes": {
      "first_name": "Skylar",
      "last_name": "Schipper",
      "bad_value": "'); DROP TABLE `people`; --"
    },
    "relationships": {
      "team": {
        "data": {
          "type": "team",
          "id": "1"
        }
      },
      "unknown": {
        "data": [
          { "type": "foo", "id": "1" }
        ]
      }
    }
  }
}
```

Flattened gives you:

```ruby
{ "first_name" => "Skylar", "last_name" => "Schipper", "team_id" => "1" }
```

```ruby
class PeopleController < ApplicationController
  include Onsi::Controller

  def create
    attributes = Onsi::Param.parse(params, [:first_name, :last_name], [:team])
    render_resource Person.create!(attributes.flatten)
  end
end
```
