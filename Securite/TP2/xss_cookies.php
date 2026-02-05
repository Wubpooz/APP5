<?php
include_once "session.php";
?>

<form>
  <input type="text" name="message" value=""> <br/>
  <input type="submit" value="Envoyer">
</form>

<?php
  if (isset($_GET['message'])) {
    $fp = fopen("./messages.txt", "a");
    fwrite($fp, "{$_GET['message']}<br/>");
    fclose($fp);
  }
  readfile("./messages.txt");
?>
