List:
? for my $item(@{ $_[0]->{data} }) {
    * <?= $item->{title} ?>
    * <?= $item->{author} ?>
    * <?= $item->{abstract} ?>
? }
