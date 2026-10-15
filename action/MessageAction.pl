#!C:\Strawberry\perl\bin\perl.exe
require '../object/MessageObject.pl';
require '../service/MessageService_SQLite3.pl';
require '../object/AccountObject.pl';
require '../service/AccountService_SQLite3.pl';
use Template;
use JSON;
use CGI::Session;
package MessageAction;

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
  $self->{_form} = MessageObject->new(());
  $self->{_service} = MessageService->new;
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
  $tt->process('messages.htm', {lang => $session->param('lang'), accountid => $session->param('accountId'), channelid => $self->{_form}->getChannel_Id(), sid => $self->{_form}->getSid()});
}

sub doInsert {
  my ($self) = @_;
  $self->{_service}->insert($self->{_form});
  $self->doIndex();
}

sub doGet {
  my ($self) = @_;
  @messages = $self->{_service}->retrieveMessages($self->{_form}->getChannel_Id());
  $accountService = AccountService->new;
  %jsonMessages = ();
  foreach $message (@messages){
    %jsonMessage = ();
    @account = $accountService->retrieveAccountById($message->getAccount_Id());
    $found = @account;
	if ($found > 0) {
      $jsonMessage{'accountname'} = $account[0]->getAccountname();
      $jsonMessage{'time'} = $message->getCreationdate();
      $jsonMessage{'message'} = $message->getMessage();
      $jsonMessages{$message->getId()} = \%jsonMessage;
	} else {
      $jsonMessage{'accountname'} = $message->getId();
      $jsonMessage{'time'} = $message->getCreationdate();
      $jsonMessage{'message'} = $message->getMessage();
      $jsonMessages{$message->getId()} = \%jsonMessage;
	}
  }
  $jsonMsg = $jsonMsg . "}";
  print "Content-Type: application/json\n\n";
  $json = JSON->new->ascii->pretty->allow_nonref->convert_blessed;
  print $json->encode(\%jsonMessages);
}
1;

my $messageAction = MessageAction->new;
$messageAction->doExecute();