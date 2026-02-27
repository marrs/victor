# Vic Grammar

Types are named with the `:vic.grammar/` namespace. Each type corresponds to a
validator that accepts a value and returns the validated (possibly normalised)
form, or an error.

## :vic.grammar/compass-point

One of the eight compass directions or centre:

```
:n | :ne | :e | :se | :s | :sw | :w | :nw | :c
```

```fennel
[:enum :n :ne :e :se :s :sw :w :nw :c]
```

## :vic.grammar/coord

A resolved, concrete 2D point.

```
:vic.grammar/coord = [number number]
```

```fennel
[:tuple :number :number]
```

## :vic.grammar/cardinal

A symbolic reference to a named point on a shape. Resolves to a
`:vic.grammar/coord` during layout.

```
:vic.grammar/cardinal = [:name :vic.grammar/compass-point]
```

```fennel
[:tuple :keyword :vic.grammar/compass-point]
```

## :vic.grammar/direction

Anything that can resolve to a coord or compass point. Used wherever a
direction or target position is needed.

```
:vic.grammar/direction = :vic.grammar/compass-point
                       | :vic.grammar/cardinal
                       | :vic.grammar/coord
```

```fennel
[:or
  :vic.grammar/compass-point
  :vic.grammar/cardinal
  :vic.grammar/coord]
```

## :vic.grammar/vector

A directed line between two position expressions. Used by `:midpoint`.

```
:vic.grammar/vector = [:vic.grammar/pos :vic.grammar/pos]
```

```fennel
[:tuple :vic.grammar/pos :vic.grammar/pos]
```

## :vic.grammar/polar

A magnitude paired with a direction. Requires an origin during processing to
resolve to a concrete displacement.

```
:vic.grammar/polar = [number :vic.grammar/direction]   -- e.g. [0.85 :e], [0.85 [:foo :ne]]
```

```fennel
[:tuple :number :vic.grammar/direction]
```

## :vic.grammar/pos

A symbolic position expression. Resolves to a `:vic.grammar/coord` during
layout.

```
:vic.grammar/pos = :vic.grammar/coord
                 | :vic.grammar/cardinal
                 | [:midpoint :vic.grammar/vector]
                 | {:from :vic.grammar/pos :offset :vic.grammar/polar}
                 | {:x    :vic.grammar/pos :y      :vic.grammar/pos}
```

```fennel
[:or
  :vic.grammar/coord
  :vic.grammar/cardinal
  [:tuple [:= :midpoint] :vic.grammar/vector]
  [:map {:closed true}
    [:from   :vic.grammar/pos]
    [:offset :vic.grammar/polar]]
  [:map {:closed true}
    [:x :vic.grammar/pos]
    [:y :vic.grammar/pos]]]
```

## :vic.grammar/anchor

The value of an element's `:anchor` attribute — places a specific compass
point of the element at a resolved position:

```
:vic.grammar/anchor = [:vic.grammar/compass-point :vic.grammar/pos]
```

```fennel
[:tuple :vic.grammar/compass-point :vic.grammar/pos]
```
