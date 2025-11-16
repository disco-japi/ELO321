<?php require 'base.php'; ?>

<body>
  <div class="container py-3">
    <center>
      <?php
      switch ($tab) {
        case 0:
          require 'show.php';
          break;
        case 1:
          if ($login && $administrador) {
            require 'show.php';
          }
          break;
        case 2:
          if ($login && !$administrador) {
            require 'show.php';
          }
          break;
        case 3:
          require 'show.php';
          break;
        case 4:
          require 'show.php';
          break;
      } ?>
    </center>
  </div>
</body>
<?php require 'footer.php'; ?>

</html>