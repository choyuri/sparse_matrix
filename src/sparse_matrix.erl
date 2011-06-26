-module(sparse_matrix).
-export([new/0, new/1, new/2,
  from_triplet/1, from_triplet/2, from_triplet/3,
  from_list/1, from_list/2, from_list/3,
  get/2, put/2, delete/2, coordinates/1, dimensions/1,
  add/2, mult/2 ]).
-include("sparse_matrix.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCTORS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
new() -> #sparse_matrix{}.
new(Default) -> #sparse_matrix{default=Default}.
new(Default,Sym) -> #sparse_matrix{default=Default, symmetric=Sym}.

from_triplet(Triplets) -> from_triplet(Triplets, 0).
from_triplet(Triplets, Default) ->
  from_list([ {{R,C},V} || {R,C,V} <- Triplets ], Default).
from_triplet(Triplets, Default, Symmetry) ->
	from_list([ {{R,C},V} || {R,C,V} <- Triplets ], Default,Symmetry).	

from_list(List) -> from_list(List, 0).
from_list(List, Default) ->
  MaxR = max_rows(List, hd(List)),
  MaxC = max_cols(List, hd(List)),
  from_list(List, Default, false, {MaxR,MaxC}).

from_list(List, Default,Symmetry) ->
  MaxR = max_rows(List, hd(List)),
  MaxC = max_cols(List, hd(List)),
  from_list(List, Default, Symmetry, {MaxR,MaxC}).


from_list(List, Default, Symmetry, {MaxR,MaxC})
	when is_integer(MaxR), is_integer(MaxC) ->	
  #sparse_matrix{dims={MaxR,MaxC}, default=Default, values=List, 
								 symmetric=Symmetry}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ACCESSORS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get the get of a cell in the matrix
get({R,C}, Matrix) when is_record(Matrix,sparse_matrix) ->
  El = [Value || {{R1,C1},Value} <- Matrix#sparse_matrix.values, R1==R, C1==C],
	
	%look for symetric cell
	El2 =
    if 
	  (El == []) andalso Matrix#sparse_matrix.symmetric ->
		  [Value2 || {{R2,C2},Value2} <- Matrix#sparse_matrix.values, R2==C, C2==R];		
		true -> El
    end,

  get(El2, Matrix#sparse_matrix.default);

get([], Default) -> Default;
get([H|_], _) -> H.

    
%% Put a value into the matrix using triplet form. This replaces any existing
%% value
%% TODO Add a dimensional check
put({R,C, V}, Matrix) when is_record(Matrix,sparse_matrix) ->
  Values = lists:keystore({R,C}, 1, Matrix#sparse_matrix.values, {{R,C},V}),
  Matrix#sparse_matrix{values=Values}.

delete({R,C}, Matrix) when is_record(Matrix,sparse_matrix) ->
  
  Values = lists:keydelete({R,C}, 1, Matrix#sparse_matrix.values),
	Values2 =
		if Matrix#sparse_matrix.symmetric ->			
		  lists:keydelete({C,R}, 1, Values);
		true ->
			Values
		end,
	Matrix#sparse_matrix{values=Values2}.
 
coordinates(Matrix) when is_record(Matrix, sparse_matrix) ->
  [ {R,C} || {{R,C}, _} <- Matrix#sparse_matrix.values ].

dimensions(Matrix) when is_record(Matrix, sparse_matrix) ->
  Matrix#sparse_matrix.dims.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OPERATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add(A,B) when is_record(A,sparse_matrix), is_record(B,sparse_matrix) ->
  ASet = ordsets:from_list(coordinates(A)),
  BSet = ordsets:from_list(coordinates(B)),
  Intersection = ordsets:intersection(ASet,BSet),
  Fn = fun(Coords) -> {Coords, get(Coords,A) + get(Coords,B)} end,

  SubFn = fun(Set, Int, Matrix) ->
    [ {Tuple, V} || {Tuple, V} <- Matrix#sparse_matrix.values, 
      Unique <- ordsets:to_list(ordsets:subtract(Set, Int)), Tuple == Unique ]
  end,
  Values = lists:map(Fn, Intersection)
    ++ SubFn(ASet,Intersection,A) ++ SubFn(BSet,Intersection,B),
  from_list(Values).
  
mult(A, B) when is_record(A,sparse_matrix), is_record(B,sparse_matrix) ->
  not_implemented.
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRIVATE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get the number of rows in the matrix
max_rows(List, {{R0,_},_}) when is_integer(R0) ->
  hd(lists:reverse(lists:sort([R || {{R,_},_} <- List])));
max_rows(List, _) ->
  length(lists:usort([R || {{R,_},_} <- List])).

%% Get the number of columns in the matrix
max_cols(List, {{_,C0},_}) when is_integer(C0) ->
  hd(lists:reverse(lists:sort([C || {{_,C},_} <- List])));
max_cols(List, _) ->
  length(lists:usort([C || {{_,C},_} <- List])).
  
