using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;

namespace TankyReloaded.Actors.Shots
{
    internal class FireBall : Shot
    {
        private static Texture2D texture;
        private AnimatedSprite anim;

        public FireBall()
        {
            Width = 30;
            Height = 25;
            HorizontalSpeed = 500;
        }

        public override int Damage { get; } = 7;
        public override int HealthPoints { get; set; } = 50;

        public override void Draw(SpriteBatch spriteBatch)
        {
            anim.Draw(spriteBatch, new Vector2((float) Left, (float) Top));
            anim.Cycle();
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("spr_burnmedallionflamescaled");
            anim = new AnimatedSprite(texture, 3, 3, emptyFrames: 1, (int?) Width, (int?) Height);
            ShootSound = content.Load<SoundEffect>("sounds/nsmb_fireball");
        }

        public override void Update(GameTime gameTime)
        {
            Left += HorizontalSpeed.Apply(gameTime);
            if (this.IsOutOfBounds())
            {
                Dispose();
            }
        }

        private void Dispose()
        {
            Stage.Remove(this);
        }
    }
}