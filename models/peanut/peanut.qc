$modelname "peanut\peanut.mdl"
$body mybody "peanut_ref.smd"

$surfaceprop Concrete
$cdmaterials "models\peanut"

$sequence idle "peanut_ref.smd"

$collisionmodel "peanut_phys.smd" { $concave }