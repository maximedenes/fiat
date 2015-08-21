(** Sharpened ADT for an expression grammar with parentheses *)
Require Import Coq.Init.Wf Coq.Arith.Wf_nat.
Require Import Coq.Lists.List.
Require Import Coq.Numbers.Natural.Peano.NPeano.
Require Import Fiat.Parsers.Refinement.Tactics.
Require Import Fiat.Parsers.Grammars.ExpressionParen.
Require Import Fiat.Computation.Refinements.General.
Require Import Fiat.Parsers.StringLike.Properties.
Require Import Fiat.Parsers.StringLike.String.
Require Import Fiat.Common.
Require Import Fiat.Common.Wf.
Require Import Fiat.Parsers.Splitters.RDPList.
Require Import Fiat.Parsers.BaseTypes.
Require Import Fiat.Parsers.Refinement.FixedLengthLemmas.

Set Implicit Arguments.

Section IndexedImpl.

  Lemma ComputationalSplitter'
  : FullySharpened (string_spec paren_expr_grammar).
  Proof.

    start sharpening ADT.
    start honing parser using indexed representation.

    hone method "splits".
    {
      simplify parser splitter.
      finish honing parser method.
    }

    Time finish_SharpeningADT_WithoutDelegation.
  Defined.

  Lemma ComputationalSplitter
  : FullySharpened (string_spec paren_expr_grammar).
  Proof.
    let impl := (eval simpl in (projT1 ComputationalSplitter')) in
    refine (existT _ impl _).
    abstract (exact (projT2 ComputationalSplitter')).
  Defined.

End IndexedImpl.

Global Arguments ComputationalSplitter / .

Require Import Fiat.Parsers.ParserFromParserADT.
Require Import Fiat.Parsers.ExtrOcamlParsers.
Import Fiat.Parsers.ExtrOcamlParsers.HideProofs.

(* Ben : Taking too long to run; commenting so I can debug build.
Time Definition paren_expr_parser (str : String.string) : bool
  := Eval simpl in has_parse (parser ComputationalSplitter) str.

Print paren_expr_parser.

Recursive Extraction paren_expr_parser. *)
