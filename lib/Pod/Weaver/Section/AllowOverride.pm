#---------------------------------------------------------------------
package Pod::Weaver::Section::AllowOverride;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 31 May 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Allow POD to override a Pod::Weaver-provided section
#---------------------------------------------------------------------

use 5.010;
use Moose;
with qw(Pod::Weaver::Role::Transformer Pod::Weaver::Role::Section);

our $VERSION = '0.01';
# This file is part of Pod-Weaver-Section-AllowOverride 0.01 (June 1, 2012)

#=====================================================================


has header_re => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {'^' . quotemeta(shift->plugin_name) . '$' },
);

has _override_with => (
  is   => 'rw',
  does => 'Pod::Elemental::Node',
);

#---------------------------------------------------------------------
# Return a sub that matches a node against header_re:

sub _section_matcher
{
  my $self = shift;

  my $header_re = $self->header_re;
  $header_re    = qr/$header_re/;

  return sub {
    my $node = shift;

    return ($node->can('command') and
            $node->command eq 'head1' and
            $node->content =~ $header_re);
  } # end sub
} # end _section_matcher

#---------------------------------------------------------------------
# Look for a matching section in the original POD, and remove it temporarily:

sub transform_document
{
  my ($self, $document) = @_;

  my $match    = $self->_section_matcher;
  my $children = $document->children;

  for my $i (0 .. $#$children) {
    if ($match->( $children->[$i] )) {
      # Found matching section.  Store & remove it:
      $self->_override_with( splice @$children, $i, 1 );
      last;
    } # end if this is the section we're looking for
  } # end for $i indexing @$children
} # end transform_document

#---------------------------------------------------------------------
# If we found a section in the original POD,
# use it instead of the one now in the document:

sub weave_section
{
  my ($self, $document, $input) = @_;

  my $override = $self->_override_with;
  return unless $override;

  my $children = $document->children;

  if (@$children and $self->_section_matcher->( $children->[-1] )) {
    pop @$children;
  } else {
    $self->log(["No previous %s section to override", $override->content]);
  }

  push @$children, $override;
} # end weave_section

#=====================================================================
# Package Return Value:

__PACKAGE__->meta->make_immutable;
no Moose;
1;


__END__
=pod

=head1 NAME

Pod::Weaver::Section::AllowOverride - Allow POD to override a Pod::Weaver-provided section

=head1 VERSION

This document describes version 0.01 of
Pod::Weaver::Section::AllowOverride, released June 1, 2012.

=head1 SYNOPSIS

  [Authors]
  [AllowOverride]
  header_re = ^AUTHORS?$

=head1 DESCRIPTION

Sometimes, you might want to override a normally-generic section in
one of your modules.  This section plugin replaces the preceding
section with the corresponding section taken from your POD (if it
exists).  If your POD doesn't contain a matching section, then the
Pod::Weaver-provided one will be used.

Both the original section in your POD and the section provided by
Pod::Weaver must match the C<header_re>.  Also, this plugin must
immediately follow the section you want to replace.

It's a similar idea to L<Pod::Weaver::Role::SectionReplacer>, except
that it works the other way around.  SectionReplacer replaces the
section from your POD with a section provided by Pod::Weaver.

=head1 ATTRIBUTES

=head2 header_re

This regular expression is used to select the section you want to
override.  It's matched against the section name from the C<=head1>
line.  The default is an exact match with the name of this plugin.
(e.g. if the plugin name is AUTHOR, the default would be C<^AUTHOR$>)

=head1 SEE ALSO

L<Pod::Weaver::Role::SectionReplacer>,
L<Pod::Weaver::PluginBundle::ReplaceBoilerplate>

=for Pod::Coverage transform_document
weave_section

=head1 BUGS

Please report any bugs or feature requests to bug-pod-weaver-section-allowoverride@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-AllowOverride

=head1 AUTHOR

Christopher J. Madsen <perl@cjmweb.net>

=head1 SOURCE

The development version is on github at L<http://github.com/madsen/pod-weaver-section-allowoverride>
and may be cloned from L<git://github.com/madsen/pod-weaver-section-allowoverride.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

