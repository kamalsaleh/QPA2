InstallMethod( BasisOfHom,
        "for two representations of a quiver",
        [ IsQuiverRepresentation, IsQuiverRepresentation ],
        function( R1, R2 )

  local   A,  F,  vertices,  dim_R1,  dim_R2,  num_vert,  support_R1,  
          support_R2,  i,  num_cols,  num_rows,  block_intervals,  
          block_rows,  block_cols,  prev_col,  prev_row,  a,  
          source_arrow,  target_arrow,  equations,  arrows,  mats_R1,  
          mats_R2,  j,  row_start_pos, row_end_pos, col_start_pos, col_end_pos,
          m, n, b, homs, dim_hom, hom_basis, map, k, y, x, mat;

  A := AlgebraOfRepresentation( R1 ); 
  if A <> AlgebraOfRepresentation( R2 ) then
    Print("The two modules entered are not modules over the same algebra.");
    return fail;
  fi;
  F := LeftActingDomain(A);
  #
  # Finding the support of R1 and R2 
  # 
  vertices := Vertices( QuiverOfAlgebra( A ) );
  dim_R1 := DimensionVector( R1 );
  dim_R2 := DimensionVector( R2 );
  num_vert := Length( dim_R1 );   
  support_R1 := [];
  support_R2 := [];
  for i in [ 1..num_vert ] do
    if ( dim_R1[ i ] <> 0 ) then 
      AddSet( support_R1, i );
    fi;
    if ( dim_R2[ i ] <> 0 ) then 
      AddSet( support_R2, i );
    fi;
  od;
  #
  # Deciding the size of the equations, 
  # number of columns and rows
  #
  num_cols := 0;
  num_rows := 0;
  block_intervals := [];
  block_rows := [];
  block_cols := [];
  prev_col := 0;
  prev_row := 0;
  for i in support_R1 do
    num_rows := num_rows + dim_R1[ i ] * dim_R2[ i ];
    block_rows[ i ] := prev_row + 1;
    prev_row := num_rows;
    for a in OutgoingArrows( vertices[ i ] ) do
      source_arrow := VertexIndex( Source( a ) );
      target_arrow := VertexIndex( Target( a ) );
      if ( target_arrow in support_R2 ) and 
         ( ( source_arrow in support_R2 ) or ( target_arrow in support_R1 ) ) then 
        num_cols := num_cols + dim_R1[ source_arrow ] * dim_R2[ target_arrow ];
        Add( block_cols, [ a, prev_col + 1, num_cols ] );
      fi;
      prev_col := num_cols; 
    od;
  od;
  if num_rows = 0 then
    return [];
  fi;
  #
  # Finding the linear equations for the maps between M and N
  #
  equations := MutableNullMat( num_rows, num_cols, F);
  arrows := Arrows( QuiverOfAlgebra( A ) );
  mats_R1 := List( MapsOfRepresentation( R1 ), m -> RowsOfMatrix( RightMatrixOfLinearTransformation( m ) ) ); 
  mats_R2 := List( MapsOfRepresentation( R2 ), m -> RowsOfMatrix( RightMatrixOfLinearTransformation( m ) ) ); 
  prev_col := 0;
  prev_row := 0;
  for i in support_R1 do
    for a in OutgoingArrows( vertices[i] ) do
      source_arrow := VertexIndex( Source( a ) );
      target_arrow := VertexIndex( Target( a ) );
      if ( target_arrow in support_R2 ) and 
         ( ( source_arrow in support_R2 ) or ( target_arrow in support_R1 ) ) then
        for j in [ 1..dim_R1[ source_arrow ] ] do
          row_start_pos := block_rows[ source_arrow ] + ( j - 1 ) * dim_R2[ source_arrow ]; 
          row_end_pos := block_rows[ source_arrow ] - 1 + j * dim_R2[ source_arrow ];
          col_start_pos := prev_col + 1 + ( j-1 ) * dim_R2[ target_arrow ];
          col_end_pos := prev_col + j * dim_R2[ target_arrow ];
          if ( source_arrow in support_R2 ) then 
            equations{ [ row_start_pos..row_end_pos ] }{ [ col_start_pos..col_end_pos ] } := 
              mats_R2[ ArrowIndex( a ) ];
          fi;
          if ( target_arrow in support_R1 ) then 
            for m in [ 1..DimensionsMat( mats_R1[ ArrowIndex( a ) ] )[ 2 ] ] do
              for n in [ 1..dim_R2[ target_arrow ] ] do
                b := block_rows[ target_arrow ] + (m - 1) * dim_R2[ target_arrow ];
                equations[ b + n - 1 ][ col_start_pos + n - 1 ] := 
                  equations[ b + n - 1 ][ col_start_pos + n - 1 ] + (-1) * mats_R1[ ArrowIndex( a ) ][ j ][ m ];
              od;
            od;
          fi;
        od;
        prev_col := prev_col + dim_R1[ source_arrow ] * dim_R2[ target_arrow ];
      fi;
    od;
  od;
  #
  # Creating the maps between the module M and N
  #
  if num_cols = 0 then 
    equations := NullMat( num_rows, num_cols + 1, F);
  fi;
  homs := [];
  dim_hom := 0;
  hom_basis := NullspaceMat( equations );
  for b in hom_basis do
    map := [];
    dim_hom := dim_hom + 1;
    k := 1;
    for i in [ 1..num_vert ] do 
      if ( dim_R1[ i ] <> 0 ) and ( dim_R2[ i ] <> 0 ) then 
        mat := MutableNullMat( dim_R1[ i ], dim_R2[ i ], F );
        for y in [ 1..dim_R1[ i ] ] do 
          for x in [ 1..dim_R2[ i ] ] do 
            mat[ y ][ x ] := b[ k ];
            k := k + 1;
          od;
        od;
        map[ i ] := MatrixByRows( F, mat );
      fi;
    od;
    homs[dim_hom] := QuiverRepresentationHomomorphism( R1, R2, map );
  od;
  
  return homs;
end
  );

