------------------------------------------------------------------------
-- The Agda standard library
--
-- The basic code for equational reasoning with three relations:
-- equality, strict ordering and non-strict ordering.
------------------------------------------------------------------------
--
-- See `Data.Nat.Properties` or `Relation.Binary.Reasoning.PartialOrder`
-- for examples of how to instantiate this module.

open import Relation.Binary

module Relation.Binary.Reasoning.Base.Triple {a ℓ₁ ℓ₂ ℓ₃} {A : Set a}
  {_≈_ : Rel A ℓ₁} (isEquivalence : IsEquivalence _≈_)
  {_≤_ : Rel A ℓ₂} (≤-trans : Transitive _≤_) (≤-resp-≈ : _≤_ Respects₂ _≈_) (≤-refl : Reflexive _≤_)
  {_<_ : Rel A ℓ₃} (<-trans : Transitive _<_) (<-resp-≈ : _<_ Respects₂ _≈_) (<⇒≤ : _<_ ⇒ _≤_)
  (<-≤-trans : Trans _<_ _≤_ _<_)
  (≤-<-trans : Trans _≤_ _<_ _<_)
  where

open import Data.Product using (proj₁; proj₂)
open import Level using (Level; _⊔_; Lift; lift)
open import Function using (case_of_; id)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

open IsEquivalence isEquivalence
  renaming
  ( refl  to ≈-refl
  ; sym   to ≈-sym
  ; trans to ≈-trans
  )

------------------------------------------------------------------------
-- A datatype to hide the current relation type

data _∼_ (x y : A) : Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃) where
  strict    : (x<y : x < y) → x ∼ y
  nonstrict : (x≤y : x ≤ y) → x ∼ y
  equals    : (x≈y : x ≈ y) → x ∼ y

levelOf : ∀ {x y} → x ∼ y → Level
levelOf (strict    x<y) = ℓ₃
levelOf (nonstrict x≤y) = ℓ₂
levelOf (equals    x≈y) = ℓ₁

relOf : ∀ {x y} (r : x ∼ y) → Rel A (levelOf r)
relOf (strict    x<y) = _<_
relOf (nonstrict x≤y) = _≤_
relOf (equals    x≈y) = _≈_

------------------------------------------------------------------------
-- A record that is used to ensure that the final relation proved by the
-- chain of reasoning can be converted into the required relation.

record Entails {r s} (R : Rel A r) (S : Rel A s) : Set (a ⊔ r ⊔ s) where
  field entails : R ⇒ S
open Entails {{...}}

instance
  ≈-entails-≤ : Entails _≈_ _≤_
  ≈-entails-≤ = record
    { entails = λ z → proj₁ ≤-resp-≈ z ≤-refl
    }

  <-entails-≤ : Entails _<_ _≤_
  <-entails-≤ = record
    { entails = <⇒≤
    }

  id-Entails : ∀ {r} {R : Rel A r} → Entails R R
  id-Entails = record
    { entails = id
    }

------------------------------------------------------------------------
-- Reasoning combinators

infix -1 begin_
infixr 0 _<⟨_⟩_ _≤⟨_⟩_ _≈⟨_⟩_ _≡⟨_⟩_ _≡⟨⟩_
infix  1 _∎

begin_ : ∀ {r x y} {R : Rel A r} (r : x ∼ y) {{ _ : Entails (relOf r) R }} → R x y
begin (strict    x<y) = entails x<y
begin (nonstrict x≤y) = entails x≤y
begin (equals    x≈y) = entails x≈y

_<⟨_⟩_ : ∀ (x : A) {y z} → x < y → y ∼ z → x ∼ z
x <⟨ x<y ⟩ strict    y<z = strict (<-trans x<y y<z)
x <⟨ x<y ⟩ nonstrict y≤z = strict (<-≤-trans x<y y≤z)
x <⟨ x<y ⟩ equals    y≈z = strict (proj₁ <-resp-≈ y≈z x<y)

_≤⟨_⟩_ : ∀ (x : A) {y z} → x ≤ y → y ∼ z → x ∼ z
x ≤⟨ x≤y ⟩ strict    y<z = strict    (≤-<-trans x≤y y<z)
x ≤⟨ x≤y ⟩ nonstrict y≤z = nonstrict (≤-trans x≤y y≤z)
x ≤⟨ x≤y ⟩ equals    y≈z = nonstrict (proj₁ ≤-resp-≈ y≈z x≤y)

_≈⟨_⟩_ : ∀ (x : A) {y z} → x ≈ y → y ∼ z → x ∼ z
x ≈⟨ x≈y ⟩ strict    y<z = strict    (proj₂ <-resp-≈ (≈-sym x≈y) y<z)
x ≈⟨ x≈y ⟩ nonstrict y≤z = nonstrict (proj₂ ≤-resp-≈ (≈-sym x≈y) y≤z)
x ≈⟨ x≈y ⟩ equals    y≈z = equals    (≈-trans x≈y y≈z)

_≡⟨_⟩_ : ∀ (x : A) {y z} → x ≡ y → y ∼ z → x ∼ z
x ≡⟨ x≡y ⟩ strict    y<z = strict    (case x≡y of λ where refl → y<z)
x ≡⟨ x≡y ⟩ nonstrict y≤z = nonstrict (case x≡y of λ where refl → y≤z)
x ≡⟨ x≡y ⟩ equals    y≈z = equals    (case x≡y of λ where refl → y≈z)

_≡⟨⟩_ : ∀ (x : A) {y} → x ∼ y → x ∼ y
x ≡⟨⟩ x∼y = x∼y

_∎ : ∀ x → x ∼ x
x ∎ = equals ≈-refl

------------------------------------------------------------------------
-- Some examples and tests

private
  module Examples where
    postulate
      u v w x y z d e : A
      u≈v : u ≈ v
      v≡w : v ≡ w
      w<x : w < x
      x≤y : x ≤ y
      y<z : y < z
      z≡d : z ≡ d
      d≈e : d ≈ e

    u≤c : u < e
    u≤c = begin
      u ≈⟨ u≈v ⟩
      v ≡⟨ v≡w ⟩
      w <⟨ w<x ⟩
      x ≤⟨ x≤y ⟩
      y <⟨ y<z ⟩
      z ≡⟨ z≡d ⟩
      d ≈⟨ d≈e ⟩
      e ∎

    u≤y : u ≤ y
    u≤y = begin
      u ≈⟨ u≈v ⟩
      v ≡⟨ v≡w ⟩
      w ≤⟨ <⇒≤ (<-≤-trans w<x x≤y) ⟩
      y ∎

    u≈w : u ≈ w
    u≈w = begin
      u ≈⟨ u≈v ⟩
      v ≡⟨ v≡w ⟩
      w ∎
