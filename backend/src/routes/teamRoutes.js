const express = require("express");
const { body } = require("express-validator");
const teamController = require("../controllers/teamController");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.use(authMiddleware);

router.get("/", teamController.listTeams);
router.post(
  "/",
  [
    body("name")
      .trim()
      .isLength({ min: 2 })
      .withMessage("Team name is required"),
  ],
  teamController.createTeam
);
router.get("/:teamId", teamController.getTeamDetails);
router.put(
  "/:teamId",
  [
    body("name")
      .trim()
      .isLength({ min: 2 })
      .withMessage("Team name is required"),
  ],
  teamController.updateTeam
);
router.delete("/:teamId", teamController.deleteTeam);
router.post(
  "/:teamId/members",
  [body("email").isEmail().withMessage("Valid email required")],
  teamController.addMemberByEmail
);
router.delete(
  "/:teamId/members",
  [body("userId").isInt().withMessage("Valid user ID required")],
  teamController.removeMember
);
router.post("/:teamId/leave", teamController.leaveTeam);
router.post(
  "/:teamId/transfer-leadership",
  [body("newLeaderId").isInt().withMessage("Valid user ID required")],
  teamController.transferLeadership
);

module.exports = router;
