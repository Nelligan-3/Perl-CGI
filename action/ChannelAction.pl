#!C:\Strawberry\perl\bin\perl.exe
require '../object/ChannelObject.pl';
require '../service/ChannelService_SQLite3.pl';
use Template;
use JSON;
use CGI::Session;
package ChannelAction;

sub new {
  my $class = shift;
  my $self = {
    _service => shift,
    _form => shift,
  };
  return bless $self, $class;
}

sub doExecute {
  my ($self) = @_;
  $self->{_form} = ChannelObject->new(());
  $self->{_service} = ChannelService->new;
  $session = CGI::Session->new($self->{_form}->getSid());
  if($self->{_form}->getAction() eq 'insert') {
    $self->doInsert();
  }elsif($self->{_form}->getAction() eq 'get'){
    $self->doGet();
  }else{
    $self->doIndex();
  }
}

sub doIndex {
  my ($self) = @_;
  print "Content-Type: text/html\n\n";
  my $tt = Template->new({INCLUDE_PATH => '../templates'});
  $tt->process('channels.htm', {lang => $session->param('lang'), accountid => $session->param('accountId'), sid => $self->{_form}->getSid()});
}

sub doInsert {
  my ($self) = @_;
  $self->{_service}->insert($self->{_form});
  $self->doIndex();
}

sub doGet {
  my ($self) = @_;
  @channels = $self->{_service}->retrieveChannels($session->param('lang'));
  %jsonChannels = ();
  foreach $channel (@channels){
    $jsonChannels{$channel->getId()} = $channel->getName();
  }
  print "Content-Type: application/json\n\n";
  $json = JSON->new->ascii->pretty->allow_nonref->convert_blessed;
  print $json->encode(\%jsonChannels);
}
1;

my $channelAction = ChannelAction->new;
$channelAction->doExecute();