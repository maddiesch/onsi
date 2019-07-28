# Changelog

## Version 2.0.0

### unreleased

- Added pagination support

- Fix: Relationships without a valid value now render a `nil` data structure. This is a breaking change. To keep the old behavior you can use `legacy_relationship_render!`

    ```ruby
    api_render(:v1) do
      legacy_relationship_render!
    end
    ```

## Version 1.3.0

### Released March 19, 2019

- Fix: CORS headers

## Version 1.2.2

### Released February 23, 2019

#### Changes

- Feat: Allow passing in a metadata object to `#render_resource`.

---

## Version 1.2.1

### Released February 23, 2019 (3)

- Feat: Allow setting a different primary id attribute.

- Fix: Rename method named `#object_id`

---

## Version 1.2.0

### Released February 23, 2019 (2)

- Feat: Allow setting a different primary id attribute.

---

## Version 1.1.0

### Released February 23, 2019 (1)

- Feat: Add CORS headers helpers.

- Feat: Allow Params to parse included relationships

---

## Version 1.0.1

### Released November 21, 2018

- Fix for nested complex attributes.

---

## Version 1.0.0

### Released November 15, 2018

- The first official release of Onsi.

### Upgrading

- There are no breaking changes from 0.8.0 to 1.0.0
