function [ newlabel newtitle ] = wlAux_makeSafeString( oldstring )

% function [ newlabel newtitle ] = wlAux_makeSafeString( oldstring )
%
% This function makes label- and title-safe versions of an input string.
% The label-safe version strips anything that's not alphanumeric.
% The title-safe version replaces stripped characters with spaces.
%
% This is more aggressive than filename- or fieldname-safe strings; in
% particular, underscores are interpreted as typesetting metacharacters
% in plot labels and titles.
%
% This accepts character vectors (single strings) or cell arrays (lists of
% strings), returning the same type.
%
% "oldstring" is a character vector to convert, or a cell array of character
%   vectors to convert.
%
% "newlabel" is a character vector with only alphanumeric characters, or
%   a cell array of such character vectors.
% "newtitle" is a character vector with non-alphanumeric characters replaced
%   with spaces, or a cell array of such character vectors.


if iscell(oldstring)

  % We have a list of strings.
  % Recurse to process each list item.

  newlabel = {};
  newtitle = {};

  for lidx = 1:length(oldstring)
    [ thislabel thistitle ] = wlAux_makeSafeString( oldstring{lidx} );
    newlabel{lidx} = thislabel;
    newtitle{lidx} = thistitle;
  end

else

  % We have a single string.
  % Use vector operations instead of going letter by letter.

  digitmask = (oldstring >= '0') & (oldstring <= '9');
  lettermask = isletter(oldstring);
  keepmask = digitmask | lettermask;

  % For the label, discard anything that wasn't alphanumeric.
  newlabel = oldstring(keepmask);

  % For the title, replace anything that wasn't alphanumeric with spaces.
  newtitle = oldstring;
  newtitle(~keepmask) = ' ';

end


% Done.

end


%
% This is the end of the file.
