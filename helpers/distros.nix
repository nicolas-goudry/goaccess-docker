rec {
  alpine-3 = alpine;
  alpine-3-22 = alpine;
  debian-12 = debian;
  debian-12-slim = debian-slim;
  debian-bookworm = debian;
  debian-bookworm-slim = debian-slim;
  ubuntu-25 = ubuntu;

  alpine = {
    imageName = "alpine";
    imageDigest = "sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1";
    sha256 = "sha256-q+3QkoaQYK1Yp/69NIGoxHSv2WpyeBVWFwcFGhnApUY=";
  };

  debian = {
    imageName = "debian";
    imageDigest = "sha256:b6507e340c43553136f5078284c8c68d86ec8262b1724dde73c325e8d3dcdeba";
    sha256 = "sha256-xnBbz+kxJCnJVUv80UuOoVl/Cndxtiif+QJjLkqKaSU=";
  };

  debian-slim = {
    imageName = "debian";
    imageDigest = "sha256:2424c1850714a4d94666ec928e24d86de958646737b1d113f5b2207be44d37d8";
    sha256 = "sha256-pmSrMOFpytThyKVbtw+G2U2qSWIdbjBuGEPJXOV8aO8=";
  };

  ubuntu = {
    imageName = "ubuntu";
    imageDigest = "sha256:95a416ad2446813278ec13b7efdeb551190c94e12028707dd7525632d3cec0d1";
    sha256 = "sha256-tjossjSJuqW9ZRsmhpWBL2w56bIxKQoG7azgcBulmIU=";
  };
}
