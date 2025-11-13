<!DOCTYPE html>
<html>
<?php require 'base.php'; ?>

<body onload="checkradio();">
	<?php
	if (array_key_exists("create", $_POST)) {
		$info = '';
		$nombre_usuario = $_POST["username"];
		$check = $conn->query("select nombre_usuario from Persona where nombre_usuario = '$nombre_usuario'");
		if ($check != false && $check->num_rows > 0) {
			$info = "Ya existe un usuario con ese nombre.<br>";
		} else if ($check != false) {
			$rut = $_POST["rut"];
			$passwd = $_POST["passwd"];
			$nombre = $_POST["nombre"];
			$rol = $_POST["rol"];
			$email = $_POST["email"];
			if ($conn->query("CALL registrar_persona('$rut','$nombre','$email','$nombre_usuario','$passwd','$rol')") != false) {
				if ($rol == "ingeniero") {
					$especialidad = $_POST["esp"];
					$conn->query("INSERT INTO `Ingeniero_Topico` (`rut_ingeniero`, `id_topico`) VALUES ('$rut', '$especialidad');");
				}
				$info = "Usuario creado con exito, por favor, inicie sesión con sus credenciales.<br>";
			} else {
				$info = "Error desconocido.<br>";
			}
		}
	?>
		<div class="container">
			<center>
				<div class="alert alert-primary" role="alert">
					<?php echo $info; ?>
				</div>
			</center>
		</div>
	<?php } ?>
	<center>
		<script type="text/javascript">
			function checkradio() {
				if (document.getElementById('ing').checked) {
					document.getElementById("esp").style.display = '';
				} else {
					document.getElementById("esp").style.display = 'none';
				}
			}

			function validate() {
				let field = [];
				let passmismatch = false;
				if (document.getElementById("passwd2").value != document.getElementById("passwd").value) {
					document.getElementById("error").innerHTML += "\nLas contraseñas no coinciden";
					return false;
				} else {
					return true;
				}
			}
		</script>
		<div class="container py-2">
			<h2> Registro </h2>
			<form class="p-4 p-md-5 border rounded-3 bg-body-tertiary" style="max-width:50%;" action="register.php" method="POST" onsubmit="return validate();">
				<input type="hidden" name="create" value="true" />
				<div class="form-floating mb-3"><input class="form-control" maxlength="50" required type="text" label="name" name="nombre" id="name" placeholder="Nombre y apellido"><label for="name">Nombre y apellido</label></div>
				<div class="form-floating mb-3"><input class="form-control" maxlength="50" required type="text" label="username" name="username" id="username" placeholder="Nombre de usuario"><label for="username">Nombre de usuario</label></div>
				<div class="form-floating mb-3"><input class="form-control" maxlength="50" required type="email" label="email" name="email" id="email" placeholder="E-Mail"><label for="email">E-Mail</label></div>
				<div class="form-floating mb-3"><input class="form-control" maxlength="12" required type="text" label="rut" name="rut" id="rut" placeholder="RUT"><label for="rut">RUT</label></div>
				¿Que rol cumples?<br>
				<input type="radio" class="form-check-input" id="usr" name="rol" value="usuario" checked="true" oninput="checkradio()">
				<label for="usr">Usuario</label><br>
				<input type="radio" class="form-check-input" id="ing" name="rol" value="ingeniero" oninput="checkradio()">
				<label for="ing">Ingeniero</label><br>
				<div id="esp">
					<label for="esp">Selecciona una especialidad</label><br>
					<select class="form-select mb-3" name="esp">
						<option value="1">Backend</option>
						<option value="2">Seguridad</option>
						<option value="3">UX/UI</option>
					</select>
				</div>
				<div class="form-floating mb-3"><input class="form-control" maxlength="255" required type="password" label="passwd" name="passwd" id="passwd" placeholder="Contraseña"><label for="passwd">Contraseña</label></div>
				<div class="form-floating mb-3"><input class="form-control" maxlength="255" required type="password" label="passwd2" name="passwd2" id="passwd2" placeholder="Confirmación de contraseña"><br><label for="passwd2">Confirmación de contraseña</label></div>
				<input type="submit" class="btn btn-primary px-4" value="Registro" />
				<hr class="my-4">
				<small class="text-body-secondary">¿Ya estás registrado? <a href="login.php">Inicia Sesión</a></small>
				<p id=error style="color:red;"></p>
		</div>
		</div>
		</form>
		</div>
	</center>
</body>
<?php require 'footer.php'; ?>

</html>