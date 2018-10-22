DeclareSideOperations( IsQuiverAlgebraIdeal,
                       IsQuiverAlgebraLeftIdeal, IsQuiverAlgebraRightIdeal,
                       IsQuiverAlgebraTwoSidedIdeal );

DeclareSideOperations( QuiverAlgebraIdeal,
                       QuiverAlgebraLeftIdeal, QuiverAlgebraRightIdeal,
                       QuiverAlgebraTwoSidedIdeal );

InstallMethodWithSides( QuiverAlgebraIdeal, [ IsQuiverAlgebra, IsDenseList ],
side -> function( A, gens )
  local I, ideal_cat, type;
  I := rec();
  if IsPathAlgebra( A ) and side = LEFT_RIGHT then
    ideal_cat := IsQuiverAlgebraIdeal ^ side and IsPathAlgebraIdeal;
  else
    ideal_cat := IsQuiverAlgebraIdeal ^ side;
  fi;    
  type := NewType( FamilyObj( A ),
                   ideal_cat
                   and IsComponentObjectRep
                   and IsAttributeStoringRep );
  ObjectifyWithAttributes( I, type,
                           Side, side,
                           AlgebraOfIdeal, A,
                           Generators, gens );
  return I;
end );

InstallMethod( LeftIdealByGenerators, [ IsQuiverAlgebra, IsCollection and IsDenseList ],
               QuiverAlgebraLeftIdeal );
InstallMethod( RightIdealByGenerators, [ IsQuiverAlgebra, IsCollection and IsDenseList ],
               QuiverAlgebraRightIdeal );
InstallMethod( TwoSidedIdealByGenerators, [ IsQuiverAlgebra, IsCollection and IsDenseList ],
               QuiverAlgebraTwoSidedIdeal );
               

InstallMethod( String, "for quiver algebra ideal",
               [ IsQuiverAlgebraIdeal ],
function( I )
  local side_str, gens_str;
  if Side( I ) = LEFT_RIGHT then
    side_str := "two-sided";
  else
    side_str := String( Side( I ) );
  fi;
  if IsEmpty( Generators( I ) ) then
    return Concatenation( "<", side_str, " zero ideal>" );
  fi;
  gens_str := Iterated( List( Generators( I ), String ),
                        function( a, b ) return Concatenation( a, ", ", b ); end );
  return Concatenation( "<", side_str, " ideal generated by ", gens_str, ">" );
end );

InstallMethod( ViewObj, "for quiver algebra ideal",
               [ IsQuiverAlgebraIdeal ],
function( I )
  Print( String( I ) );
end );

# operations from GAP:
InstallMethod( GeneratorsOfLeftIdeal, [ IsQuiverAlgebraLeftIdeal ], Generators );
InstallMethod( GeneratorsOfRightIdeal, [ IsQuiverAlgebraRightIdeal ], Generators );
InstallMethod( GeneratorsOfTwoSidedIdeal, [ IsQuiverAlgebraTwoSidedIdeal ], Generators );
InstallMethod( LeftActingRingOfIdeal, [ IsQuiverAlgebraLeftIdeal ], AlgebraOfIdeal );
InstallMethod( LeftActingRingOfIdeal, [ IsQuiverAlgebraTwoSidedIdeal ], AlgebraOfIdeal );
InstallMethod( RightActingRingOfIdeal, [ IsQuiverAlgebraRightIdeal ], AlgebraOfIdeal );
InstallMethod( RightActingRingOfIdeal, [ IsQuiverAlgebraTwoSidedIdeal ], AlgebraOfIdeal );
InstallMethod( IsIdeal, "for ring and quiver algebra ideal",
               [ IsRing, IsQuiverAlgebraIdeal ],
function( R, I )
  return R = AlgebraOfIdeal( I );
end );

InstallMethod( IdealAsSubmoduleOfAlgebra, [ IsQuiverAlgebraIdeal ],
function( I )
  local side, A;
  A := AlgebraOfIdeal( I );
  if not IsFiniteDimensional( A ) then
    Error( "algebra is not finite-dimensional" );
  fi;
  side := Side( I );
  return SubmoduleInclusion( AlgebraAsModule( side, A ),
                             List( Generators( I ), AsModuleElement ^ side ) );
end );

InstallMethod( IdealAsModule, [ IsQuiverAlgebraIdeal ],
               I -> Source( IdealAsSubmoduleOfAlgebra( I ) ) );

InstallMethod( \in, [ IsQuiverAlgebraElement, IsQuiverAlgebraIdeal ],
function( a, I )
  local inc, M, module_elem;
  inc := IdealAsSubmoduleOfAlgebra( I );
  M := IdealAsModule( I );
  module_elem := PreImagesRepresentative( inc, AsModuleElement( Side( M ), a ) );
  return module_elem <> fail;
end );

InstallMethod( GroebnerBasis, "for path algebra ideal",
               [ IsPathAlgebraIdeal ],
               I -> ComputeGroebnerBasis( Generators( I ) ) );

InstallMethod( \in, "for element of path algebra and path algebra ideal",
               [ IsPathAlgebraElement, IsPathAlgebraIdeal ],
function( e, I )
  return e in AlgebraOfIdeal( I )
         and IsZero( Reduce( e, GroebnerBasis( I ) ) );
end );

InstallMethod( IdealElementAsModuleElement, [ IsQuiverAlgebraElement, IsQuiverAlgebraIdeal ],
function( a, I )
  local inc, M, module_elem;
  inc := IdealAsSubmoduleOfAlgebra( I );
  M := IdealAsModule( I );
  module_elem := PreImagesRepresentative( inc, AsModuleElement( Side( M ), a ) );
  if module_elem = fail then
    Error( "algebra element ", a, " is not in the ideal ", I );
  fi;
  return module_elem;
end );

InstallMethod( ModuleElementAsIdealElement, [ IsQuiverModuleElement, IsQuiverAlgebraIdeal ],
function( m, I )
  local inc;
  inc := IdealAsSubmoduleOfAlgebra( I );
  return AsAlgebraElement( Image( inc, m ) );
end );

InstallMethod( IsAdmissibleIdeal, [ IsPathAlgebraIdeal ],
function( I )
  local gens, kQ, Q, A, is_reducible, path_length, paths, next_paths, p, a;

  gens := GeneratorsOfIdeal( I );
  
  # check I \subseteq J^2:
  if not ForAll( gens, g -> ForAll( Paths( g ), IsCompositePath ) ) then
    return false;
  fi;

  # check J^t \subseteq I:
  kQ := LeftActingRingOfIdeal( I );
  Q := QuiverOfAlgebra( kQ );
  A := kQ / I;

  if not IsFiniteDimensional( A ) then
    return false;
  fi;

  is_reducible :=
    p ->
    ( Representative( PathAsAlgebraElement( A, p ) )
      <> PathAsAlgebraElement( PathAlgebra( A ), p ) );

  path_length := 1;
  paths := Arrows( Q );
  next_paths := [];

  while not ForAll( paths, is_reducible ) do
    for p in paths do
      for a in OutgoingArrows( Target( p ) ) do
        Add( next_paths, ComposePaths( p, a ) );
      od;
    od;
    path_length := path_length + 1;
    paths := next_paths;
    next_paths := [];
  od;

  return ForAll( paths, p -> IsZero( PathAsAlgebraElement( A, p ) ) );
end );

InstallMethod( IsZeroIdeal, "for quiver algebra ideal",
               [ IsQuiverAlgebraIdeal ],
function( I )
  return ForAll( Generators( I ), IsZero );
end );

BindGlobal( "FamilyOfQuiverAlgebraIdealBases",
            NewFamily( "quiver ideal bases" ) );

InstallMethod( CanonicalBasis, "for quiver algebra ideal",
               [ IsQuiverAlgebraIdeal ],
function( I )
  local basis_vectors, type, B;
  if not IsFiniteDimensional( AlgebraOfIdeal( I ) ) then
    Error( "not implemented" );
  fi;
  basis_vectors := List( Basis( IdealAsModule( I ) ),
                         m -> ModuleElementAsIdealElement( m, I ) );
  type := NewType( FamilyOfQuiverAlgebraIdealBases,
                   IsQuiverAlgebraIdealBasis and IsComponentObjectRep
                   and IsAttributeStoringRep );
  B := rec();
  ObjectifyWithAttributes( B, type,
                           IdealOfBasis, I,
                           BasisVectors, basis_vectors,
                           IsCanonicalBasis, true );
  return B;
end );

InstallMethod( Basis, "for quiver algebra ideal",
               [ IsQuiverAlgebraIdeal ],
               CanonicalBasis );

InstallMethod( UnderlyingLeftModule, "for quiver algebra ideal basis",
               [ IsQuiverAlgebraIdealBasis ],
               IdealOfBasis );
