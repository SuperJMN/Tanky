using System;
using Microsoft.Xna.Framework;

namespace TankyReloaded
{
    public static class StageObjectMixin 
    {
        public static bool Collides(this IStageObject self, IStageObject another)
        {
            return self.Bounds.Intersects(another.Bounds);
        }

        public static bool IsTouchingGround(this IStageObject self, double step)
        {
            return self.Bounds.Bottom + step >= Constants.GroundTop;
        }

        public static bool IsTouchingGround(this IStageObject self)
        {
            return Math.Abs(self.Bounds.Bottom - Constants.GroundTop) < 2;
        }

        public static bool IsFlying(this IStageObject self, double step)
        {
            return !self.IsTouchingGround(step);
        }

        public static bool IsOutOfBounds(this IStageObject self)
        {
            return !self.Stage.GetBounds().Intersects(self.Bounds);
        }
    }

    public static class StageMixin
    {
        public static Rectangle GetBounds(this IStage stage)
        {
            return new Rectangle(0, 0, (int) stage.Width, (int) stage.Height);
        }
    }
}