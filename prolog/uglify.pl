
:- module(uglify,
    [
      uglify/0
    ]).

:- use_module(library('semweb/rdfs')).
:- use_module(library('semweb/rdf_db')).

ease_ugly_ontology('http://www.ease-crc.org/ont/SOMA-UGLY.owl').

ease_assert(_Graph, rdf(_S,_P,O)) :-
  rdf_equal(O,owl:'Ontology'),!.

ease_assert(Graph, rdf(_S,P,O)) :-
  rdf_equal(P,owl:imports),!,
  ease_assert_import(Graph,O).

ease_assert(Graph, rdf(S,P,O)) :-
  soma_iri(S,S0),
  soma_iri(P,P0),
  soma_iri(O,O0),
  rdf_assert(S0,P0,O0,Graph).

% convert any 'http://www.ease-crc.org/SOMA[.*].owl#[.*]' IRI
% to 'http://www.ease-crc.org/SOMA.owl#[.*]'
soma_iri(IN,IN) :-
  \+ atom(IN),
  !.
soma_iri(IN,OUT) :-
  ( atom_concat('http://www.ease-crc.org/SOMA',_,IN)
  -> soma_iri1(IN,OUT)
  ;  OUT=IN
  ).
soma_iri1(IN,OUT) :-
  rdf_split_url(_,Name,IN),
  atom_concat('http://www.ease-crc.org/SOMA.owl#',Name,OUT).

%%
ease_assert_import(Graph,Ontology) :-
  % ignore all imports of EASE ontology modules
  ( atom_concat('http://www.ease-crc.org/',_,Ontology) ;
    atom_concat('package://soma/',_,Ontology)
  ),!.

ease_assert_import(Graph,Ontology) :-
  ease_ugly_ontology(EASE_UGLY),
  rdf_assert(EASE_UGLY,owl:imports,Ontology,Graph).

ease_load(URL, Graph) :-
  load_rdf(URL, Triples, [blank_nodes(noshare)]),
  maplist(ease_assert(Graph), Triples).

uglify :-
  ease_ugly_ontology(EASE_UGLY),
  Ontologies=[
    'SOMA.owl',
    'SOMA-ACT.owl',
    'SOMA-WF.owl',
    'SOMA-IO.owl',
    'SOMA-OBJ.owl',
    %'SOMA-STATE.owl',
    %'SOMA-SAY.owl',
    'SOMA-PROC.owl'
  ],
  rdf_assert(EASE_UGLY,rdf:type,owl:'Ontology',ease),
  source_file(uglify, Filepath),
  string_concat(Basepath, '/prolog/uglify.pl', Filepath),
  forall(member(N,Ontologies), (
      atomic_list_concat([Basepath, '/owl/', N], GlobalPath),
      ease_load(GlobalPath,ease)
  )),
  %%%
  atomic_list_concat([Basepath, '/owl/SOMA-UGLY.owl'], OUT_Path),
  rdf_save(OUT_Path, [graph(ease),sorted(true)]).

