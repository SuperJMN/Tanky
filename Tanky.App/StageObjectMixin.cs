using System;
using Microsoft.Xna.Framework;
using SuperJMN.MonoGame;

namespace TankyApp
{
    public static class StageObjectMixin
    {
        public static bool WillTouchGround(this IStageObject self, GameTime gameTime)
        {
            var nextY = self.VerticalSpeed.Apply(gameTime);
            return self.Bounds.Bottom + nextY >= Constants.GroundTop;
        }

        public static bool IsTouchingGround(this IStageObject self)
        {
            return Math.Abs(self.Bounds.Bottom - Constants.GroundTop) < 2;
        }
    }
}