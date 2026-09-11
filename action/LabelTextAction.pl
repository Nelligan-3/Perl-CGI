#!C:\Strawberry\perl\bin\perl.exe
require '../object/LabelTextObject.pl';
require '../service/LabelTextService_SQLite3.pl';
use JSON;
use CGI::Session;
package LabelTextAction;

sub new {
  my $class = shift;
  my $self = {
    _service => shift,
    _form => shift,
	_db => shift,
  };
  return bless $self, $class;
}

sub doExecute {
  my ($self) = @_;
  $self->{_form} = LabelTextObject->new(());
  if($self->{_form}->getSid() != 0) {
	$session = CGI::Session->new($self->{_form}->getSid());
  } else {
	$session = undef;
  }
  $self->{_service} = LabelTextService->new;
  $self->doGet();
}

sub doGet {
  my ($self) = @_;
  @labelTexts = ();
  #if (defined($session)) {
    #@labelTexts = $self->{_service}->retrieveLabelTexts($self->{_form}->getPage(), $session->param('lang'));
  #} else {
  @labelTexts = $self->{_service}->retrieveLabelTexts($self->{_form}->getPage(), $self->{_form}->getLang());
  #}
  %jsonLabelTexts = ();
  foreach $obj (@labelTexts){
	$jsonLabelTexts{$obj->getPosition()} = $obj->getLabelText();
  }
  print "Content-Type: application/json\n\n";
  $json = JSON->new->ascii->pretty->allow_nonref->convert_blessed;
  print $json->encode(\%jsonLabelTexts);
}
1;

my $labelTextAction = LabelTextAction->new;
$labelTextAction->doExecute();
