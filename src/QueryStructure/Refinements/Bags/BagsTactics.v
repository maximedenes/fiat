Require Import BagsInterface.
Require Import AdditionalLemmas.

Ltac is_sumbool expr :=
  match type of expr with
    | (sumbool _ _) => idtac
    | _ => fail
  end.

Ltac unfold_functions expr :=
  match expr with
    | appcontext [ ?f _ ] => unfold f
  end.

Ltac destruct_ifs_inside conditional :=
  match conditional with 
    | context [ if ?sub_conditional then _ else _ ] => destruct_ifs_inside sub_conditional 
    | _ => first [ is_sumbool conditional; destruct conditional | progress unfold_functions conditional ]
  end.

Ltac destruct_ifs :=
  intros;
  repeat (match goal with
            | [ |- ?body ] => 
              destruct_ifs_inside body
          end; simpl in *).

Ltac prove_extensional_eq :=
  clear;
  unfold ExtensionalEq;
  destruct_ifs; first [ solve [intuition] | solve [exfalso; intuition] | idtac ].

Require Import String Arith.

Example ifs_destruction : 
  forall w x y z,
    (if (if string_dec w x then true else false) then (if eq_nat_dec y z then false else true) else (if eq_nat_dec z y then true else false)) = (if (if eq_nat_dec y z then true else false) then (if string_dec x w then false else true) else (if string_dec x w then true else false)).
Proof.
  destruct_ifs; intuition.
Qed.

Require Import QueryStructureNotations.
Require Import ListImplementation.

Tactic Notation "lift" "list" "property" constr(prop) "as" ident(name) :=
  pose proof prop as name;
  setoid_rewrite EnsembleIndexedListEquivalence_lift_property in name;
  [ | eassumption].

Tactic Notation "call" "eapply" constr(hypothesis) "after" tactic1(preprocessor) :=
  first [ preprocessor; eapply hypothesis | eapply hypothesis ].

Tactic Notation 
       "rewrite" "filter" "over" reference(indexed_storage) 
       "using" "search" "term" constr(keyword) :=
  match goal with
    | [ (*TODO: storage: BagType ?ind, *) H: EnsembleIndexedListEquivalence ?table (benumerate ?storage) 
        |- appcontext [ filter ?filter1 (benumerate ?storage) ] ] => 
      let temp := fresh in 
      let filter2 := constr:(bfind_matcher (Bag := BagProof indexed_storage) keyword) in
      assert (ExtensionalEq filter1 filter2) as temp by prove_extensional_eq;
        rewrite (filter_by_equiv filter1 filter2 temp);
        clear temp
  end.

Tactic Notation 
       "rewrite" "dependent" "filter" constr(filter1)
       "over" reference(indexed_storage) 
       "using" "dependent" "search" "term" constr(keyword) :=
  let temp := fresh in
  let filter2 := constr:(fun x => bfind_matcher (Bag := BagProof indexed_storage) (keyword x)) in
  assert (forall x, ExtensionalEq (filter1 x) (filter2 x)) as temp by prove_extensional_eq;
    setoid_rewrite (filter_by_equiv_meta filter1 filter2 temp);
    clear temp.


(* The following tactic is useful when we have a set of hypotheses
     of the form

     H0 : In DB tuple
     H  : tupleAgree tuple <COL :: x, ...> COL
     H' : forall tuple', In DB tuple' -> (tuple'!COL <> x)

     which essentially means that we have a tuple that's in the DB and
     matches another one on the COL column, and an hypothesis H' that
     guarantees that such a match is in fact impossible. In that case,
     it's essentially enough to call exfalso, which this tactic does
 *)

Tactic Notation "prove" "trivial" "constraints" :=
  unfold decides, not in *;
  intros;
  match goal with
    | [ H: tupleAgree _ _ (?column :: _) |- _ ] =>
      specialize (H column);
        exfalso;
        match goal with
          | [ H': _ |- _] =>
            eapply H';
              try eassumption;
              call eapply H after symmetry;
              simpl;
              auto
        end
  end.

Definition ID {A} := fun (x: A) => x.

Lemma ens_red :
  forall {heading TContainer TSearchTerm} x y (y_is_bag: Bag TContainer _ TSearchTerm),
    @EnsembleIndexedListEquivalence heading x (benumerate (Bag := y_is_bag) y) =
    (ID (fun y => EnsembleIndexedListEquivalence x (benumerate y))) y.
Proof.
  intros; reflexivity.
Qed.

(* Workaround Coq's algorithms not being able to infer ther arguments to refineEquiv_pick_pair *)
Ltac refineEquiv_pick_pair_benumerate :=
  setoid_rewrite ens_red;
  setoid_rewrite refineEquiv_pick_pair;
  unfold ID; cbv beta.